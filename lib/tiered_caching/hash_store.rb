module TieredCaching
  class HashStore
    extend Forwardable

    def_delegator :@hash, :[]=, :set
    def_delegator :@hash, :[], :get
    def_delegators :@hash, :delete, :clear

    def initialize(hash)
      @hash = hash
    end

    def getset(key)
      @hash[key] ||= yield
    end

  end
end