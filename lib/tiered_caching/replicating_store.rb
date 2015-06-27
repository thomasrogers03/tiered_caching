module TieredCaching
  class ReplicatingStore
    def initialize(internal_stores, replication_factor = nil)
      @internal_stores = internal_stores
      @replication_factor = replication_factor || internal_stores.count
    end

    def set(key, value)
      replication_range(key).map do |index|
        @internal_stores[store_index(index)].set(key, value)
      end
    end

    def get(key)
      index = store_index(key.hash)
      recursive_get(key, index)
    end

    private

    def internal_get(key, start_index, index)
      return nil if start_index == index

      recursive_get(key, index)
    end

    def recursive_get(key, index)
      @internal_stores[index].get(key) || internal_get(key, index, store_index(index+1))
    end

    def replication_range(key)
      start_index = key.hash
      end_index = start_index + @replication_factor
      (start_index...end_index)
    end

    def store_index(index)
      index % @internal_stores.count
    end
  end
end