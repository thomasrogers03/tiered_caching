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
      value
    end

    def get(key)
      index = store_index(hash_for_key(key))
      end_index = store_index(hash_for_key(key) + @replication_factor)
      recursive_get(key, end_index, index)
    end

    def delete(key)
      replication_range(key).map do |index|
        @internal_stores[store_index(index)].delete(key)
      end
    end

    def clear
      @internal_stores.map(&:clear)
    end

    private

    def internal_get(key, end_index, index)
      return nil if end_index == index

      recursive_get(key, end_index, index)
    end

    def recursive_get(key, end_index, index)
      store = @internal_stores[index]
      store.get(key) || begin
        Logging.logger.warn("ReplicatingStore: Cache miss at level #{index}")
        result = internal_get(key, end_index, store_index(index+1))
        result && store.set(key, result)
      end
    end

    def replication_range(key)
      start_index = hash_for_key(key)
      end_index = start_index + @replication_factor
      (start_index...end_index)
    end

    def store_index(index)
      index % @internal_stores.count
    end

    def hash_for_key(key)
      Digest::MD5.hexdigest(key.to_s).unpack('L').first
    end
  end
end