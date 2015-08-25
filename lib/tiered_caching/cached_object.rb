module TieredCaching
  module CachedObjectStatic
    Attributes = Struct.new(:on_missing_callback)

    def cache_line=(value)
      @cache_line = value
    end

    def on_missing(&callback)
      attributes[:on_missing_callback] = callback
    end

    def [](key)
      if on_missing_callback
        cache.getset(internal_key(key)) { on_missing_callback.call(key) }
      else
        cache.get(internal_key(key))
      end
    end

    def []=(key, value)
      raise TypeError, "Cannot convert #{value.class} into #{self}" unless value.is_a?(self)

      cache.set(class: self, key: key) { value }
    end

    def delete(key)
      cache.delete(class: self, key: key)
    end

    private

    def cache
      CacheMaster[@cache_line]
    end

    def on_missing_callback
      attributes[:on_missing_callback]
    end

    def internal_key(key)
      {class: self, key: key}
    end

    def attributes
      @attributes ||= Attributes.new
    end

  end

  module CachedObject

    def self.included(base)
      base.send(:extend, CachedObjectStatic)
    end

    def save_to_cache(key)
      self.class[key] = self
    end

  end
end
