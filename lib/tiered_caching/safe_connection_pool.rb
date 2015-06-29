module TieredCaching
  class SafeConnectionPool
    def initialize(internal_pool)
      @internal_pool = internal_pool
    end

    def with(&block)
      @internal_pool.with { |conn| safe_with(conn, &block) }
    end

    def disabled?
      !!@disabled
    end

    private

    def safe_with(conn)
      return nil if disabled?

      begin
        yield conn
      rescue
        @disabled = true
        nil
      end
    end

  end
end