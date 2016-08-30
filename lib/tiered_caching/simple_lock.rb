module TieredCaching
  class SimpleLock
    LOCK_PATH = File.join(TieredCaching.root, 'tiered_caching/simple_lock/lock.lua')
    LOCK_SCRIPT = File.read(LOCK_PATH)

    def initialize(store, key, ttl = 5)
      @store = store
      @key = key
      @id = SecureRandom.base64
      @ttl = ttl
      @script_sha = @store.script(:load, LOCK_SCRIPT)
    end

    def lock
      @store.evalsha(@script_sha, keys: [@key], argv: [@id, @ttl])
    end

    def heartbeat
      @store.expire(@key, @ttl)
    end

    def unlock
      @store.del(@key)
    end

  end
end
