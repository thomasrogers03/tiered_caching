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

    def lock(timeout = nil)
      timeout ? lock_with_timeout(timeout) : lock_without_timeout
    end

    def heartbeat
      @store.expire(@key, @ttl)
    end

    def unlock
      @store.del(@key)
    end

    def synchronize(timeout = nil)
      lock(timeout)
      yield
    ensure
      unlock
    end

    private

    def lock_without_timeout
      sleep 1 until try_lock
    end

    def lock_with_timeout(timeout)
      try_count = 0
      until try_lock
        try_count += 1
        raise 'Timed out waiting for lock!' if try_count > timeout
        sleep 1
      end
    end

    def try_lock
      @store.evalsha(@script_sha, keys: [@key], argv: [@id, @ttl]) == @id
    end

  end
end
