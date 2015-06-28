require 'rspec'

module TieredCaching
  describe ReplicatingStore do
    let(:internal_stores) { [global_store] }
    let(:replication_factor) { 1 }
    let(:hash) { 1234567890 }
    let(:key) { 'key' }
    let(:value) { 'value' }

    subject { ReplicatingStore.new(internal_stores, replication_factor) }

    before { allow(key).to receive(:hash).and_return(hash) }

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
        let(:store_count) { 2 }
        let(:internal_stores) { store_count.times.map { StoreHelpers::MockStore.new } }

        it 'should save the value to the store bucketed by the hash of the key' do
          subject.set(key, value)
          expect(internal_stores[0].get(key)).to eq(value)
        end

        it 'should return the specified value' do
          expect(subject.set(key, value)).to eq(value)
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

          it 'should return the specified value' do
            expect(subject.set(key, value)).to eq(value)
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

    describe '#get' do
      before { global_store.set(key, value) }

      it 'should retrieve the value from the underlying store' do
        expect(subject.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'window' }

        it 'should retrieve the value from the underlying store' do
          expect(subject.get(key)).to eq(value)
        end
      end

      context 'with multiple underyling stores' do
        let(:hash) { 7 }
        let(:store_count) { 5 }
        let(:replication_factor) { store_count }
        let(:store_on_token) { hash % store_count }
        let(:store_with_value) { store_on_token }
        let(:internal_stores) { store_count.times.map { StoreHelpers::MockStore.new } }

        before { internal_stores[store_with_value].set(key, value) }

        it 'should retrieve the value from the store matching the token of the key' do
          expect(subject.get(key)).to eq(value)
        end

        context 'when the value is not available from the store matching the token' do
          let(:store_with_value) { (hash + 1) % store_count }

          it 'should retrieve the value from the first store containing the value' do
            expect(subject.get(key)).to eq(value)
          end

          context 'when the value is deeper' do
            let(:store_with_value) { (hash + 3) % store_count }

            it 'should retrieve the value from the first store containing the value' do
              expect(subject.get(key)).to eq(value)
            end

            it 'should fill in the value on all stores in the replication range' do
              subject.get(key)
              expect(internal_stores[store_on_token].get(key)).to eq(value)
              expect(internal_stores[store_on_token+1].get(key)).to eq(value)
            end
          end
        end

        context 'with a different replication factor' do
          let(:replication_factor) { 1 }
          let(:store_with_value) { (hash + 1) % store_count }

          it 'should should not search any deeper than the replication factor' do
            expect(subject.get(key)).to be_nil
          end
        end

      end

    end

  end
end