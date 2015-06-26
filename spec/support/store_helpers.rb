module StoreHelpers
  extend RSpec::Core::SharedContext

  class MockStore
    extend Forwardable

    def_delegator :@store, :[], :get
    def_delegator :@store, :[]=, :set
    def_delegator :@store, :clear
    def_delegator :@store, :empty?

    def initialize
      @store = {}
    end

    def getset(key)
      @store[key] ||= yield
    end
  end

  let(:global_store) { MockStore.new }

  before { TieredCaching::CacheMaster.reset! }
end