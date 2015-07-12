module TieredCaching
  class AsyncStore

    def initialize(store_pool, executor)
      @store_pool = store_pool
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

    def getset(key, &block)
      internal_store { |conn| conn.getset(key, &block) }
    end

    def delete(key)
      internal_store { |conn| conn.delete(key) }
    end

    def clear
      internal_store { |conn| conn.clear }
    end

    private

    def internal_store(&block)
      @store_pool.with(&block)
    end

  end
end