module TieredCaching
  class RedisStore
    extend Forwardable

    GETSET_PATH = File.join(TieredCaching.root, 'tiered_caching/redis_store/getset.lua')
    GETSET_SCRIPT = File.read(GETSET_PATH)

    GETSET_TTL_PATH = File.join(TieredCaching.root, 'tiered_caching/redis_store/getset_ttl.lua')
    GETSET_TTL_SCRIPT = File.read(GETSET_TTL_PATH)

    def_delegator :@connection, :del, :delete
    def_delegator :@connection, :flushall, :clear

    def initialize(connection, ttl = nil)
      @connection = connection
      @active_connection = @connection
      @ttl = ttl
    end

    def set(key, value)
      with_connection(:set) do |connection|
        connection.set(key, value)
        connection.expire(key, @ttl) if @ttl
      end
      value
    end

    def get(key)
      with_connection(:get) { |connection| connection.get(key) }
    end

    def getset(key)
      with_connection(:getset) do |connection|
        if @ttl
          connection.evalsha(getset_ttl_sha(connection), keys: [key], argv: [yield, @ttl])
        else
          connection.evalsha(getset_sha(connection), keys: [key], argv: [yield])
        end
      end
    end

    private

    def getset_sha(connection)
      @getset_sha ||= connection.script(:load, GETSET_SCRIPT)
    end

    def getset_ttl_sha(connection)
      @getset_ttl_sha ||= connection.script(:load, GETSET_TTL_SCRIPT)
    end

    def with_connection(action)
      if @disconnect_time
        if Time.now >= (@disconnect_time + 5)
          @active_connection = @connection
        end
      end

      if @active_connection
        begin
          yield @active_connection
        rescue => e
          Logging.logger.warn("Error calling ##{action} on redis store: #{e}")
          @active_connection = nil
          @getset_sha = nil
          @disconnect_time = Time.now
          nil
        end
      end
    end

  end
end
