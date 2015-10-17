module TieredCaching
  class RedisStore
    extend Forwardable

    def_delegator :@connection, :get
    def_delegator :@connection, :del, :delete
    def_delegator :@connection, :flushall, :clear

    def initialize(connection)
      @connection = connection
      @active_connection = @connection
    end

    def set(key, value)
      with_connection(:set) { |connection| connection.set(key, value) }

      value
    end

    def getset(key)
      script = %q{local key = KEYS[1]
local value = redis.call('get', key)
if value then
  return value
else
  redis.call('set', key, ARGV[1])
  return ARGV[1]
end}
      @getset_sha ||= @connection.script(:load, script)
      @connection.evalsha(@getset_sha, keys: [key], argv: [yield])
    end

    private

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
          @disconnect_time = Time.now
        end
      end
    end

  end
end