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

  end
end