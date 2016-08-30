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
      sleep 1 until try_lock
    end

    def heartbeat
      @store.expire(@key, @ttl)
    end

    def unlock
      @store.del(@key)
    end

    def synchronize
      lock
      yield
      unlock
    end

    private

    def try_lock
      @store.evalsha(@script_sha, keys: [@key], argv: [@id, @ttl]) == @id
    end

  end
end
