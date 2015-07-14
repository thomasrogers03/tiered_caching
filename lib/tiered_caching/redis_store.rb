module TieredCaching
  class RedisStore
    extend Forwardable

    def_delegators :@connection, :get, :set
    def_delegator :@connection, :del, :delete
    def_delegator :@connection, :flushall, :clear

    def initialize(connection)
      @connection = connection
    end

    def getset(key)
      script = %q{local value = redis.call('get', KEYS[1])
if value
  return value
else
  redis.call('set', ARGV[1])
  return ARGV[1]
end}
      @getset_sha ||= @connection.script(:load, script)
      @connection.evalsha(@getset_sha, key, yield)
    end

  end
end