module TieredCaching
  class CacheLine

    def initialize(name)
      @name = name
      @tiers = []
    end

    def <<(tier)
      tiers << tier
    end

    def set(key, value = nil)
      (value || yield).tap { |value| tiers.map { |store| store.set(key, value) } }
    end

    def get(key)
      internal_get(key)
    end

    def getset(key, &block)
      get(key) || set(key, &block)
    end

    def clear(depth)
      tiers[0...depth].map(&:clear)
    end

    private

    attr_reader :tiers, :name

    def internal_get(key, tier_index = 0)
      return nil if tier_index >= tiers.count

      tier = tiers[tier_index]
      tier.get(key) || begin
        Logging.logger.warn("#{name}: Cache miss at level #{tier_index}")
        result = internal_get(key, tier_index + 1)
        result && tier.set(key, result)
      end
    end

  end
end