module TieredCaching
  class CacheMaster
    #noinspection RubyClassVariableUsageInspection
    @@tiers = []

    class << self
      def <<(tier)
        @@tiers << tier
      end

      def set(key)
        value = yield
        @@tiers.map { |store| store.set(key, value) }
        value
      end

      def get(key)
        @@tiers.each do |tier|
          result = tier.get(key)
          return result if result
        end
        nil
      end

      def getset(key, &block)
        get(key) || set(key, &block)
      end

      def clear(depth)
        @@tiers[0...depth].map(&:clear)
      end
    end

  end
end