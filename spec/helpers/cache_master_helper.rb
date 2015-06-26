module TieredCaching
  class CacheMaster
    def self.reset!
      #noinspection RubyClassVariableUsageInspection
      @@tiers.clear
    end
  end
end