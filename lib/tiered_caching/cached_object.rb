module TieredCaching
  module CachedObjectStatic

    def [](key)
      CacheMaster.get(class: self, key: key)
    end

  end

  module CachedObject

    def self.included(base)
      base.send(:extend, CachedObjectStatic)
    end

  end
end
