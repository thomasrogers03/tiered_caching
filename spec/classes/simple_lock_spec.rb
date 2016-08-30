require 'rspec'

module TieredCaching
  describe SimpleLock do

    let(:key) { Faker::Lorem.sentence }
    let(:lock_id) { SecureRandom.base64 }
    let(:store_klass) { redis_store_klass }
    let(:store) { store_klass.new }
    let(:script) { File.read(SimpleLock::LOCK_PATH) }
    let(:sha) { store.script(:load, script) }

    subject { SimpleLock.new(store, key) }

    before do
      allow(SecureRandom).to receive(:base64).and_return(lock_id)
      allow(subject).to receive(:sleep)
    end

    describe '#lock' do
      it 'runs the locking script' do
        expect(store).to receive(:evalsha).with(sha, keys: [key], argv: [lock_id, 5]).and_return(lock_id)
        subject.lock
      end

      context 'with an overridden timeout' do
        let(:ttl) { rand(6..100) }

        subject { SimpleLock.new(store, key, ttl) }

        it 'runs the locking script with the specified timeout' do
          expect(store).to receive(:evalsha).with(sha, keys: [key], argv: [lock_id, ttl]).and_return(lock_id)
          subject.lock
        end
      end

      context 'when the lock has already been acquired elsewhere' do
        let(:other_lock_id) { Faker::Lorem.sentence }
        let(:locks) { [other_lock_id, other_lock_id, lock_id] }

        before { allow(store).to receive(:evalsha).and_return(*locks) }

        it 'should wait for a lock' do
          expect(subject).to receive(:sleep).with(1).exactly(2).times
          subject.lock
        end

        context 'when a timeout is specified' do
          let(:timeout) { 1 }

          it 'should raise an error indicating that it was unable to retrieve the lock' do
            expect { subject.lock(timeout) }.to raise_error('Timed out waiting for lock!')
          end

          context 'when the timeout is sufficient to wait for it to be unlocked' do
            let(:timeout) { 2 }

            it 'should not raise an error' do
              expect { subject.lock(timeout) }.not_to raise_error
            end
          end
        end
      end
    end

    describe '#heartbeat' do
      before do
        store.set(key, lock_id)
        subject.heartbeat
      end

      it 'refreshes the ttl on the key' do
        expect(store.ttl(key)).to be_within(0.1).of(5)
      end

      context 'with an overridden timeout' do
        let(:ttl) { rand(6..100) }

        subject { SimpleLock.new(store, key, ttl) }

        it 'refreshes the ttl on the key with the specified ttl' do
          expect(store.ttl(key)).to be_within(0.1).of(ttl)
        end
      end
    end

    describe '#unlock' do
      before do
        store.set(key, lock_id)
        subject.unlock
      end

      it 'deletes the key' do
        expect(store.get(key)).to be_nil
      end
    end

    describe '#synchronize' do
      let(:callee) { double(:mock_block, call: nil) }
      let(:block) { ->() { callee.call } }

      it 'should lock, yield, then unlock' do
        expect(subject).to receive(:lock).ordered
        expect(callee).to receive(:call).ordered
        expect(subject).to receive(:unlock).ordered
        subject.synchronize(&block)
      end

      context 'with a timeout specified' do
        let(:timeout) { rand(1..100) }

        it 'should lock using the specified timeout' do
          expect(subject).to receive(:lock).with(timeout)
          subject.synchronize(timeout, &block)
        end
      end
    end

  end
end
