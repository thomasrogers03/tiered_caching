module TieredCaching
  class CacheMaster
    #noinspection RubyClassVariableUsageInspection
    @@tiers = []

    class << self
      def <<(tier)
        @@tiers << tier
      end

      def set(key)
        @@tiers.each { |store| store.set(key, yield) }
      end
    end

  end
end