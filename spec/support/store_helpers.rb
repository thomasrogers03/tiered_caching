module StoreHelpers
  extend RSpec::Core::SharedContext

  class MockStore
    extend Forwardable

    def_delegator :@store, :[], :get
    def_delegator :@store, :[]=, :set
    def_delegators :@store, :clear, :empty?, :delete

    def initialize
      @store = {}
    end

    def getset(key)
      @store[key] ||= yield
    end
  end

  class MockKeySerializingStore < MockStore
    def get(key)
      @store[serialized_key(key)]
    end

    def set(key, value)
      @store[serialized_key(key)] = value
    end

    def getset(key)
      @store[serialized_key(key)] ||= yield
    end

    private

    def serialized_key(key)
      Digest::MD5.hexdigest(Marshal.dump(key))
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
  let(:global_serializing_store) { MockKeySerializingStore.new }

  before { TieredCaching::CacheMaster.reset! }
end
