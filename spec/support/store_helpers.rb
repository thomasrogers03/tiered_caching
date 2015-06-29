module StoreHelpers
  extend RSpec::Core::SharedContext

  class MockStore
    extend Forwardable

    def_delegator :@store, :[], :get
    def_delegator :@store, :[]=, :set
    def_delegators :@store, :clear, :empty?

    def initialize
      @store = {}
    end

    def getset(key)
      @store[key] ||= yield
    end
  end

  class MockExecutor
    def post(*args, &block)
      @args = args
      @callback = block
    end

    def call
      @callback.call(*@args) if @callback
    end

    def reset!
      @args = nil
      @callback = nil
    end
  end

  let(:global_store) { MockStore.new }

  before { TieredCaching::CacheMaster.reset! }
end