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
      if attributes[:on_missing_callback]
        CacheMaster[@cache_line].getset({class: self, key: key}, &attributes[:on_missing_callback])
      else
        CacheMaster[@cache_line].get(class: self, key: key)
      end
    end

    def []=(key, value)
      raise TypeError, "Cannot convert #{value.class} into #{self}" unless value.is_a?(self)

      CacheMaster[@cache_line].set(class: self, key: key) { value }
    end

    def delete(key)
      CacheMaster[@cache_line].delete(class: self, key: key)
    end

    private

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
