require 'rspec'

module TieredCaching
  describe CacheMaster do
    let(:key) { 'key' }
    let(:value) { 'value' }

    before { CacheMaster << global_store }

    describe '.set' do

      it 'should save the specified item to the underlying store' do
        CacheMaster.set(key) { value }
        expect(global_store.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'door' }

        it 'should save the specified item to the underlying store' do
          CacheMaster.set(key) { value }
          expect(global_store.get(key)).to eq(value)
        end
      end

      context 'with multiple cache layers' do
        let(:lower_cache) { StoreHelpers::MockStore.new }

        before { CacheMaster << lower_cache }

        it 'should save the items to all underlying stores' do
          CacheMaster.set(key) { value }
          expect(global_store.get(key)).to eq(value)
          expect(lower_cache.get(key)).to eq(value)
        end
      end
    end

    describe '.get' do
      before { global_store.set(key, value) }

      it 'should be the value set in the underlying store' do
        expect(CacheMaster.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'door' }

        it 'should be the value set in the underlying store' do
          expect(CacheMaster.get(key)).to eq(value)
        end
      end


      context 'with multiple cache layers' do
        let(:lower_cache) { StoreHelpers::MockStore.new }

        before do
          CacheMaster << lower_cache
          lower_cache.set(key, value)
        end

        it 'should only request from the first cache layer' do
          expect(lower_cache).not_to receive(:get)
          CacheMaster.get(key)
        end

        context 'when the key-value pair is only available in a lower level of cache' do
          before { global_store.set(key, nil) }

          it 'should request the value from a lower tier' do
            expect(CacheMaster.get(key)).to eq(value)
          end
        end
      end

    end

    describe '.clear' do
      let(:lower_cache) { StoreHelpers::MockStore.new }

      before do
        CacheMaster << lower_cache
        CacheMaster.set(key) { value }
      end

      it 'should clear up to the specified level of cache' do
        CacheMaster.clear(1)
        expect(global_store).to be_empty
      end

      it 'should not clear any deeper than the specified level' do
        CacheMaster.clear(1)
        expect(lower_cache).not_to be_empty
      end

      context 'when requesting to clear a lower level of cache' do
        it 'should clear multiple levels of cache' do
          CacheMaster.clear(2)
          expect(global_store).to be_empty
          expect(lower_cache).to be_empty
        end
      end
    end

  end
end