module TieredCaching
  #noinspection RubyClassVariableUsageInspection
  class CacheMaster
    @@cache_line = nil

    class << self
      extend Forwardable

      def_delegators :cache_line, :<<, :set, :get, :getset, :clear

      private

      def cache_line
        @@cache_line ||= CacheLine.new(self.to_s)
      end
    end

  end
end