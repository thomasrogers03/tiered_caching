module TieredCaching
  shared_examples_for 'a tiered cache' do

    let(:key) { 'key' }
    let(:value) { 'value' }

    before { allow(Logging.logger).to receive(:warn) }

    shared_examples_for 'a cache line' do
      describe '#set' do

        it 'should save the specified item to the underlying store' do
          cache_line.set(key) { value }
          expect(global_store.get(key)).to eq(value)
        end

        it 'should return the value of the block' do
          expect(cache_line.set(key) { value }).to eq(value)
        end

        context 'when not using a block to set the value' do
          it 'should save the specified item to the underlying store' do
            cache_line.set(key, value)
            expect(global_store.get(key)).to eq(value)
          end

          it 'should return the specified value' do
            expect(cache_line.set(key, value)).to eq(value)
          end

          context 'with a different key-value pair' do
            let(:key) { 'lock' }
            let(:value) { 'door' }

            it 'should save the specified item to the underlying store' do
              cache_line.set(key) { value }
              expect(global_store.get(key)).to eq(value)
            end

            it 'should return the value of the block' do
              expect(cache_line.set(key) { value }).to eq(value)
            end
          end
        end

        context 'with a different key-value pair' do
          let(:key) { 'lock' }
          let(:value) { 'door' }

          it 'should save the specified item to the underlying store' do
            cache_line.set(key) { value }
            expect(global_store.get(key)).to eq(value)
          end

          it 'should return the value of the block' do
            expect(cache_line.set(key) { value }).to eq(value)
          end
        end

        context 'with multiple cache layers' do
          let(:lower_cache) { StoreHelpers::MockStore.new }

          before { cache_line << lower_cache }

          it 'should save the items to all underlying stores' do
            cache_line.set(key) { value }
            expect(global_store.get(key)).to eq(value)
            expect(lower_cache.get(key)).to eq(value)
          end
        end
      end

      describe '#get' do
        before { global_store.set(key, value) }

        it 'should be the value set in the underlying store' do
          expect(cache_line.get(key)).to eq(value)
        end

        context 'when no level of cache contains the key' do
          let(:value) { nil }

          it 'should be nil' do
            expect(cache_line.get(key)).to be_nil
          end
        end

        context 'with a different key-value pair' do
          let(:key) { 'lock' }
          let(:value) { 'door' }

          it 'should be the value set in the underlying store' do
            expect(cache_line.get(key)).to eq(value)
          end
        end

        context 'with multiple cache layers' do
          let(:lower_cache) { StoreHelpers::MockStore.new }

          before do
            cache_line << lower_cache
            lower_cache.set(key, value)
          end

          it 'should only request from the first cache layer' do
            expect(lower_cache).not_to receive(:get)
            cache_line.get(key)
          end

          context 'when the key-value pair is only available in a lower level of cache' do
            before { global_store.set(key, nil) }

            it 'should request the value from a lower tier' do
              expect(cache_line.get(key)).to eq(value)
            end

            it 'should move the value up to a higher level of cache for the next request' do
              cache_line.get(key)
              expect(global_store.get(key)).to eq(value)
            end

            it 'should log a cache miss at the given level' do
              expect(Logging.logger).to receive(:warn).with("#{cache_line_name}: Cache miss at level 0")
              cache_line.get(key)
            end

            context 'with numerous tiers of cache' do
              let(:lowest_cache) { StoreHelpers::MockStore.new }

              before do
                cache_line << lowest_cache
                global_store.set(key, nil)
                lower_cache.set(key, nil)
                lowest_cache.set(key, value)
              end

              it 'should request the highest tier the value exists on' do
                expect(cache_line.get(key)).to eq(value)
              end

              it 'should move the value up to a higher level of cache for the next request' do
                cache_line.get(key)
                expect(global_store.get(key)).to eq(value)
                expect(lower_cache.get(key)).to eq(value)
              end

              it 'should log a cache miss at the given level' do
                expect(Logging.logger).to receive(:warn).with("#{cache_line_name}: Cache miss at level 1")
                cache_line.get(key)
              end

              context 'when no level of cache has the value' do
                let(:value) { nil }

                it 'should not call #set on any level of cache' do
                  expect(global_store).not_to receive(:set)
                  expect(lower_cache).not_to receive(:set)
                  expect(lowest_cache).not_to receive(:set)
                  cache_line.get(key)
                end
              end
            end
          end
        end

      end

      describe '#getset' do
        let(:block) { ->() { value } }

        it 'should return the value of the passed in block' do
          expect(cache_line.getset(key, &block)).to eq(value)
        end

        it 'should return a previously set value if the key has already be assigned to a value' do
          cache_line.set(key) { 'hello' }
          expect(cache_line.getset(key, &block)).to eq('hello')
        end

        it 'should cache the result of the block' do
          cache_line.getset(key) { 'hello' }
          expect(cache_line.getset(key, &block)).to eq('hello')
        end

        context 'with a different key-value pair' do
          let(:key) { 'lock' }
          let(:value) { 'door' }

          it 'should return the value of the passed in block' do
            expect(cache_line.getset(key, &block)).to eq(value)
          end
        end
      end

    end

    describe 'managing remote cache' do
      before { cache_line << global_store }

      it_behaves_like 'a cache line'
    end

    describe 'managing local cache' do
      let(:lower_cache) { StoreHelpers::MockStore.new }

      before do
        cache_line.append_local_cache(global_store)
        cache_line << lower_cache
      end

      it_behaves_like 'a cache line'

      describe '#clear_local' do
        before { cache_line.set(key) { value } }

        it 'should delete everything from the local cache' do
          cache_line.clear_local
          expect(global_store).to be_empty
        end

        it 'should leave remote caches alone' do
          cache_line.clear_local
          expect(lower_cache.get(key)).to eq(value)
        end
      end
    end

    describe '#clear' do
      let(:lower_cache) { StoreHelpers::MockStore.new }

      before do
        cache_line << global_store
        cache_line << lower_cache
        cache_line.set(key) { value }
      end

      it 'should clear up to the specified level of cache' do
        cache_line.clear(1)
        expect(global_store).to be_empty
      end

      it 'should not clear any deeper than the specified level' do
        cache_line.clear(1)
        expect(lower_cache).not_to be_empty
      end

      context 'when requesting to clear a lower level of cache' do
        it 'should clear multiple levels of cache' do
          cache_line.clear(2)
          expect(global_store).to be_empty
          expect(lower_cache).to be_empty
        end
      end
    end

    describe 'deletion' do
      subject { cache_line }

      it_behaves_like 'a store that deletes keys'
    end

  end
end