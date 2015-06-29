module TieredCaching
  class AsyncStore

    def initialize(pool, executor)
      @pool = pool
      @executor = executor
    end

    def set(key, value)
      Concurrent::Future.execute(executor: @executor) do
        internal_store { |conn| conn.set(key, value) }
      end
      value
    end

    def get(key)
      internal_store { |conn| conn.get(key) }
    end

    private

    def internal_store(&block)
      @pool.with(&block)
    end

  end
end