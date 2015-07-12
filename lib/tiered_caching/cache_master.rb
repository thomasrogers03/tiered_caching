module TieredCaching
  #noinspection RubyClassVariableUsageInspection
  class CacheMaster
    @@cache_lines = Hash.new { |lines, key| lines[key] = CacheLine.new(key || 'CacheMaster') }

    class << self
      extend Forwardable

      def_delegators :master_line, :<<, :append_local_cache, :set, :get, :getset, :delete, :clear_local, :clear

      def [](key)
        @@cache_lines[key]
      end

      private

      def master_line
        @@cache_lines[nil]
      end
    end

  end
end