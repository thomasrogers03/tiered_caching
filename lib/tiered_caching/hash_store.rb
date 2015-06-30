module TieredCaching
  class HashStore
    extend Forwardable

    def_delegator :@hash, :[]=, :set
    def_delegator :@hash, :[], :get

    def initialize(hash)
      @hash = hash
    end

  end
end