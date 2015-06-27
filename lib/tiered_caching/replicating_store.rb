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

    private

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