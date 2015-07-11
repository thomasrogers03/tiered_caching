module TieredCaching
  class SerializingStore

    def initialize(internal_store)
      @internal_store = internal_store
    end

    def set(key, value)
      @internal_store.set(serialized_key(key), serialized_value(value))
    end

    def get(key)
      serialized_key = serialized_key(key)
      serialized_value = @internal_store.get(serialized_key)
      deserialized_value(serialized_value)
    end

    def delete(key)
      serialized_key = serialized_key(key)
      @internal_store.delete(serialized_key)
    end

    def clear
      @internal_store.clear
    end

    private

    def serialized_key(key)
      Digest::MD5.hexdigest(Marshal.dump(key))
    end

    def serialized_value(value)
      Marshal.dump(value)
    end

    def deserialized_value(serialized_value)
      Marshal.load(serialized_value) if serialized_value
    end

  end
end