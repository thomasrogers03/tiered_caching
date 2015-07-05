module TieredCaching
  #noinspection RubyClassVariableUsageInspection
  class CacheMaster
    @@cache_line = nil

    class << self
      def <<(tier)
        cache_line << tier
      end

      def set(key, value = nil, &block)
        cache_line.set(key, value, &block)
      end

      def get(key)
        cache_line.get(key)
      end

      def getset(key, &block)
        cache_line.getset(key, &block)
      end

      def clear(depth)
        cache_line.clear(depth)
      end

      private

      def cache_line
        @@cache_line ||= CacheLine.new(self.to_s)
      end
    end

  end
end