module TieredCaching
  class SafeConnectionPool
    def initialize(internal_pool, &recovery_callback)
      @internal_pool = internal_pool
      @recovery_callback = recovery_callback
    end

    def with(&block)
      @internal_pool.with { |conn| safe_with(conn, &block) }
    end

    def enable!
      @disabled = false
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
        @recovery_callback.call(self)
        nil
      end
    end

  end
end