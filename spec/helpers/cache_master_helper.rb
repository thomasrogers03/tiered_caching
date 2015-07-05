module TieredCaching
  class CacheMaster
    def self.reset!
      #noinspection RubyClassVariableUsageInspection
      @@cache_line = nil
    end
  end
end