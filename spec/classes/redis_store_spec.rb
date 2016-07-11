require 'rspec'

module TieredCaching
  describe RedisStore do

    let(:store_klass) { redis_store_klass }
    let(:store) { store_klass.new }
    let(:disconnected_error) { StandardError.new('Could not connect to redis') }
    let(:key) { 'key' }
    let(:value) { 'value' }

    subject { RedisStore.new(store) }
    before { allow(Logging.logger).to receive(:warn) }

    shared_examples_for 'a broken connection logging a warning' do |method, args|
      it 'should warn about the disconnect' do
        expect(Logging.logger).to receive(:warn).with("Error calling ##{method} on redis store: #{disconnected_error}")
        subject.public_send(method, *args)
      end

      context 'when called multiple times' do
        it 'should only log the error once' do
          subject.public_send(method, *args)
          expect(Logging.logger).not_to receive(:warn)
          subject.public_send(method, *args)
        end
      end
    end

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

        it_behaves_like 'a broken connection logging a warning', :set, %w(key value)

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

        it_behaves_like 'a broken connection logging a warning', :get, %w(key)

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
      let(:script) { File.read(RedisStore::GETSET_PATH) }
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

      context 'with a broken redis connection' do
        before { allow(store).to receive(:evalsha).and_raise(disconnected_error) }

        it 'should return nil' do
          expect(subject.getset(key) { value }).to be_nil
        end

        it 'should warn about the disconnect' do
          expect(Logging.logger).to receive(:warn).with("Error calling #getset on redis store: #{disconnected_error}")
          subject.getset(key) { value }
        end

        context 'when called multiple times' do
          it 'should only log the error once' do
            subject.getset(key) { value }
            expect(Logging.logger).not_to receive(:warn)
            subject.getset(key) { value }
          end
        end

        describe 'reconnect' do
          let(:time) { Time.at(0) }
          let(:reconnect_time) { time + 5 }

          before { mock_reconnection(:evalsha) { |_, _| value } }

          it 'should schedule a reconnect in 5s' do
            Timecop.freeze(time) { subject.getset(key) { value } }
            result = Timecop.freeze(reconnect_time) { subject.getset(key) { value } }
            expect(result).to eq(value)
          end

          it 'should invalidate the getset script' do
            Timecop.freeze(time) { subject.getset(key) { value } }
            expect(store).to receive(:script)
            Timecop.freeze(reconnect_time) { subject.getset(key) { value } }
          end
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
