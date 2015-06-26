module TieredCaching
  module CachedObjectStatic

    def [](key)
      CacheMaster.get(class: self, key: key)
    end

    def []=(key, value)
      raise TypeError, "Cannot convert #{value.class} into #{self}" unless value.is_a?(self)

      CacheMaster.set(class: self, key: key) { value }
    end

  end

  module CachedObject

    def self.included(base)
      base.send(:extend, CachedObjectStatic)
    end

  end
end
