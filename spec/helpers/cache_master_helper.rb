module TieredCaching
  class CacheMaster
    def self.reset!
      #noinspection RubyClassVariableUsageInspection
      @@cache_lines.clear
    end
  end
end