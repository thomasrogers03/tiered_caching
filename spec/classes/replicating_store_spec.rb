require 'rspec'

module TieredCaching
  describe ReplicatingStore do
    let(:internal_stores) { [global_store] }
    let(:replication_factor) { 1 }
    let(:key) { 'key' }
    let(:value) { 'value' }
    subject { ReplicatingStore.new(internal_stores, replication_factor) }

    describe '#set' do
      it 'should save the value to the underlying store' do
        subject.set(key, value)
        expect(global_store.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'door' }

        it 'should save the value to the underlying store' do
          subject.set(key, value)
          expect(global_store.get(key)).to eq(value)
        end
      end

      context 'with multiple underlying stores' do
        let(:hash) { 1234567890 }
        let(:store_count) { 2 }
        let(:internal_stores) { store_count.times.map { StoreHelpers::MockStore.new } }

        before { allow(key).to receive(:hash).and_return(hash) }

        it 'should save the value to the store bucketed by the hash of the key' do
          subject.set(key, value)
          expect(internal_stores[0].get(key)).to eq(value)
        end

        it 'should not save the value to any other store' do
          subject.set(key, value)
          expect(internal_stores[1].get(key)).to be_nil
        end

        context 'with a different key' do
          let(:key) { 'lock' }
          let(:hash) { 1234567891 }

          it 'should save the value to the store bucketed by the hash of the key' do
            subject.set(key, value)
            expect(internal_stores[1].get(key)).to eq(value)
          end

          it 'should not save the value to any other store' do
            subject.set(key, value)
            expect(internal_stores[0].get(key)).to be_nil
          end
        end

        context 'with a different replication factor' do
          let(:replication_factor) { 2 }
          let(:store_count) { 3 }

          it 'should save the value to the store bucketed by the hash of the key' do
            subject.set(key, value)
            expect(internal_stores[0].get(key)).to eq(value)
            expect(internal_stores[1].get(key)).to eq(value)
          end
        end

        context 'when the replication factor is not specified' do
          let(:store_count) { 3 }
          subject { ReplicatingStore.new(internal_stores) }

          it 'should save the value to all underlying stores' do
            subject.set(key, value)
            expect(internal_stores[0].get(key)).to eq(value)
            expect(internal_stores[1].get(key)).to eq(value)
            expect(internal_stores[2].get(key)).to eq(value)
          end

        end

      end
    end

  end
end