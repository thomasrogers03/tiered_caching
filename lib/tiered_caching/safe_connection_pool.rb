module TieredCaching
  class SafeConnectionPool

    def initialize(internal_pool)
      @internal_pool = internal_pool
    end

    def with(&block)
      @internal_pool.with { |conn| safe_with(conn, &block) }
    end

    private

    def safe_with(conn)
      yield conn rescue nil
    end

  end
end