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

    before { allow(SecureRandom).to receive(:base64).and_return(lock_id) }

    describe '#lock' do
      it 'runs the locking script' do
        expect(store).to receive(:evalsha).with(sha, keys: [key], argv: [lock_id, 5])
        subject.lock
      end

      context 'with an overridden timeout' do
        let(:ttl) { rand(6..100) }

        subject { SimpleLock.new(store, key, ttl) }

        it 'runs the locking script with the specified timeout' do
          expect(store).to receive(:evalsha).with(sha, keys: [key], argv: [lock_id, ttl])
          subject.lock
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

  end
end
