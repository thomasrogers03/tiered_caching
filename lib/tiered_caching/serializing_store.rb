module TieredCaching
  class SerializingStore

    def initialize(internal_store)
      @internal_store = internal_store
    end

    def set(key, value)
      @internal_store.set(Marshal.dump(key), Marshal.dump(value))
    end

    def get(key)
      serialized_key = Marshal.dump(key)
      serialized_value = @internal_store.get(serialized_key)
      Marshal.load(serialized_value) if serialized_value
    end

  end
end