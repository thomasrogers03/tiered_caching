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

  class MockExecutor < Concurrent::ImmediateExecutor
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

  let(:redis_store_klass) do
    Class.new do
      extend Forwardable

      def_delegator :@store, :[], :get
      def_delegator :@store, :clear, :flushall
      def_delegator :@store, :delete, :del
      def_delegator :@store, :empty?

      def initialize
        @store = Hash.new { |hash, key| hash[key] = {} }
      end

      def set(key, value)
        @store[key][:value] = value
        'OK'
      end

      def get(key)
        @store[key][:value]
      end

      def expire(key, ttl)
        if @store.include?(key)
          @store[key][:expiration] = Time.now + ttl.to_f
          1
        else
          0
        end
      end

      def ttl(key)
        @store[key][:expiration] - Time.now
      end

      def script(type, script)
        raise 'MockRedis#script only supports load!' unless type == :load

        Digest::SHA1.hexdigest(script)
      end

      #noinspection RubyUnusedLocalVariable
      def evalsha(sha, *args)
      end
    end
  end
  let(:global_store) { MockStore.new }
  let(:global_serializing_store) { MockKeySerializingStore.new }

  before { TieredCaching::CacheMaster.reset! }
end
