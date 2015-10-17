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
      if @disconnect_time
        if Time.now >= (@disconnect_time + 5)
          @active_connection = @connection
        end
      end

      if @active_connection
        begin
          @active_connection.set(key, value)
        rescue => e
          Logging.logger.warn("Error calling #set on redis store: #{e}")
          @active_connection = nil
          @disconnect_time = Time.now
        end
      end
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

  end
end