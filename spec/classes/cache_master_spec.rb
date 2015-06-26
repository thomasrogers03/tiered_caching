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

      it 'should return the value of the block' do
        expect(CacheMaster.set(key) { value }).to eq(value)
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

      context 'when no level of cache contains the key' do
        let(:value) { nil }

        it 'should be nil' do
          expect(CacheMaster.get(key)).to be_nil
        end
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

          it 'should move the value up to a higher level of cache for the next request' do
            CacheMaster.get(key)
            expect(global_store.get(key)).to eq(value)
          end

          context 'with numerous tiers of cache' do
            let(:lowest_cache) { StoreHelpers::MockStore.new }

            before do
              CacheMaster << lowest_cache
              global_store.set(key, nil)
              lower_cache.set(key, nil)
              lowest_cache.set(key, value)
            end

            it 'should request the highest tier the value exists on' do
              expect(CacheMaster.get(key)).to eq(value)
            end

            it 'should move the value up to a higher level of cache for the next request' do
              CacheMaster.get(key)
              expect(global_store.get(key)).to eq(value)
              expect(lower_cache.get(key)).to eq(value)
            end

            context 'when no level of cache has the value' do
              let(:value) { nil }

              it 'should not call #set on any level of cache' do
                expect(global_store).not_to receive(:set)
                expect(lower_cache).not_to receive(:set)
                expect(lowest_cache).not_to receive(:set)
                CacheMaster.get(key)
              end
            end
          end
        end
      end

    end

    describe '.getset' do
      let(:block) { ->() { value } }

      it 'should return the value of the passed in block' do
        expect(CacheMaster.getset(key, &block)).to eq(value)
      end

      it 'should return a previously set value if the key has already be assigned to a value' do
        CacheMaster.set(key) { 'hello' }
        expect(CacheMaster.getset(key, &block)).to eq('hello')
      end

      it 'should cache the result of the block' do
        CacheMaster.getset(key) { 'hello' }
        expect(CacheMaster.getset(key, &block)).to eq('hello')
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'door' }

        it 'should return the value of the passed in block' do
          expect(CacheMaster.getset(key, &block)).to eq(value)
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