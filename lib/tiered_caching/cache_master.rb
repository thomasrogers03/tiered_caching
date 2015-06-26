module TieredCaching
  class CacheMaster
    #noinspection RubyClassVariableUsageInspection
    @@tiers = []

    class << self
      def <<(tier)
        @@tiers << tier
      end

      def set(key)
        @@tiers.map { |store| store.set(key, yield) }
      end

      def get(key)
        @@tiers.each do |tier|
          result = tier.get(key)
          return result if result
        end
      end

      def clear(depth)
        @@tiers[0...depth].map(&:clear)
      end
    end

  end
end