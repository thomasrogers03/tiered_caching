require 'rspec'

module TieredCaching
  describe RedisStore do

    class MockRedisStore
      extend Forwardable

      def_delegator :@store, :[], :get
      def_delegator :@store, :clear, :flushall
      def_delegator :@store, :delete, :del
      def_delegator :@store, :empty?

      def initialize
        @store = {}
      end

      def set(key, value)
        @store[key] = value
        'OK'
      end

      def script(type, script)
        raise 'MockRedis#script only supports load!' unless type == :load

        Digest::SHA1.hexdigest(script)
      end

      #noinspection RubyUnusedLocalVariable
      def evalsha(sha, *args)
      end
    end

    let(:store) { MockRedisStore.new }
    let(:key) { 'key' }
    let(:value) { 'value' }

    subject { RedisStore.new(store) }

    describe '#set' do
      it 'should set the underlying key-value pair of the internal hash' do
        subject.set(key, value)
        expect(store.get(key)).to eq(value)
      end

      it 'should return the value' do
        expect(subject.set(key, value)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'cork' }
        let(:value) { :bottle }

        it 'should set the underlying key-value pair of the internal hash' do
          subject.set(key, value)
          expect(store.get(key)).to eq(value)
        end

        it 'should return the value' do
          expect(subject.set(key, value)).to eq(value)
        end
      end
    end

    describe '#get' do
      before { store.set(key, value) }

      it 'should return the value of the underlying hash object' do
        expect(subject.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'cork' }
        let(:value) { :bottle }

        it 'should return the value of the underlying hash object' do
          expect(subject.get(key)).to eq(value)
        end
      end
    end

    describe '#getset' do
      let(:script) do
        %q{local key = KEYS[1]
local value = redis.call('get', key)
if value then
  return value
else
  redis.call('set', key, ARGV[1])
  return ARGV[1]
end}
      end
      let(:sha) { store.script(:load, script) }

      it 'should execute a script executing a getset on redis conforming to other stores' do
        expect(store).to receive(:evalsha).with(sha, keys: [key], argv: [value])
        subject.getset(key) { value }
      end

      it 'should cache the sha for the script' do
        subject.getset(key) { value }
        expect(store).not_to receive(:script)
        subject.getset(key) { value }
      end

      context 'with a different key-value pair' do
        let(:key) { 'cork' }
        let(:value) { :bottle }

        it 'should execute a script executing a getset on redis conforming to other stores' do
          expect(store).to receive(:evalsha).with(sha, keys: [key], argv: [value])
          subject.getset(key) { value }
        end
      end
    end

    it_behaves_like 'a store that deletes keys'

  end
end