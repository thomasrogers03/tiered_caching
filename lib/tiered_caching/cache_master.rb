module TieredCaching
  class CacheMaster
    #noinspection RubyClassVariableUsageInspection
    @@tiers = []

    class << self
      def <<(tier)
        @@tiers << tier
      end

      def set(key)
        @@tiers.first.set(key, yield)
      end
    end

  end
end