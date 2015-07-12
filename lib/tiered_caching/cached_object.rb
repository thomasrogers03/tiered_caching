module TieredCaching
  module CachedObjectStatic
    def cache_line=(value)
      @cache_line = value
    end

    def [](key)
      CacheMaster[@cache_line].get(class: self, key: key)
    end

    def []=(key, value)
      raise TypeError, "Cannot convert #{value.class} into #{self}" unless value.is_a?(self)

      CacheMaster[@cache_line].set(class: self, key: key) { value }
    end

    def delete(key)
      CacheMaster[@cache_line].delete(class: self, key: key)
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
