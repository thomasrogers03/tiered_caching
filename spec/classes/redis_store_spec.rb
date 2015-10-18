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
    let(:disconnected_error) { StandardError.new('Could not connect to redis') }
    let(:key) { 'key' }
    let(:value) { 'value' }
    let(:redis_store) { RedisStore.new(store) }

    subject { redis_store }
    before { allow(Logging.logger).to receive(:warn) }

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

      context 'with a broken redis connection' do
        before { allow(store).to receive(:set).and_raise(disconnected_error) }

        it 'should return the specified value' do
          expect(subject.set(key, value)).to eq(value)
        end

        it 'should warn about the disconnect' do
          expect(Logging.logger).to receive(:warn).with("Error calling #set on redis store: #{disconnected_error}")
          subject.set(key, value)
        end

        context 'when called multiple times' do
          it 'should only log the error once' do
            subject.set(key, value)
            expect(Logging.logger).not_to receive(:warn)
            subject.set(key, value)
          end
        end

        describe 'reconnect' do
          let(:time) { Time.at(0) }
          let(:reconnect_time) { time + 5 }
          let(:result) { [] }

          before { mock_reconnection(:set) { |_, value| result << value } }

          it 'should schedule a reconnect in 5s' do
            Timecop.freeze(time) { subject.set(key, value) }
            Timecop.freeze(reconnect_time) { subject.set(key, value) }
            expect(result).to eq([value])
          end
        end
      end
    end

    describe '#get' do
      before { store.set(key, value) }

      it 'should return the value of the underlying redis connection' do
        expect(subject.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'cork' }
        let(:value) { 'bottle' }

        it 'should return the value of the underlying redis connection' do
          expect(subject.get(key)).to eq(value)
        end
      end

      context 'with a broken redis connection' do
        before { allow(store).to receive(:get).and_raise(disconnected_error) }

        it 'should return nil' do
          expect(subject.get(key)).to be_nil
        end

        it 'should warn about the disconnect' do
          expect(Logging.logger).to receive(:warn).with("Error calling #get on redis store: #{disconnected_error}")
          subject.get(key)
        end

        context 'when called multiple times' do
          it 'should only log the error once' do
            subject.get(key)
            expect(Logging.logger).not_to receive(:warn)
            subject.get(key)
          end
        end

        describe 'reconnect' do
          let(:time) { Time.at(0) }
          let(:reconnect_time) { time + 5 }

          before { mock_reconnection(:get) { |_, _| value } }

          it 'should schedule a reconnect in 5s' do
            Timecop.freeze(time) { subject.get(key) }
            result = Timecop.freeze(reconnect_time) { subject.get(key) }
            expect(result).to eq(value)
          end
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

    private

    def mock_reconnection(method)
      allow(store).to receive(method) do |key, value|
        if Time.now >= reconnect_time
          yield key, value
        else
          raise disconnected_error
        end
      end
    end

  end
end