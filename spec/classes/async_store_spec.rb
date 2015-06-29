require 'rspec'

module TieredCaching
  describe AsyncStore do

    let(:pool) { ConnectionPool.new(size: 1) { global_store } }
    let(:executor) { StoreHelpers::MockExecutor.new }
    let(:key) { 'key' }
    let(:value) { 'value' }

    subject { AsyncStore.new(pool, executor) }

    before { executor.reset! }

    describe '#set' do
      after { executor.call }

      it 'should call #set on the underlying store using a separate thread' do
        subject.set(key, value)
        expect(global_store).to receive(:set).with(key, value)
      end

      it 'should return the specified value' do
        expect(subject.set(key, value)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'box' }

        it 'should call #set on the underlying store using a separate thread' do
          subject.set(key, value)
          expect(global_store).to receive(:set).with(key, value)
        end

        it 'should return the specified value' do
          expect(subject.set(key, value)).to eq(value)
        end
      end
    end

    describe '#get' do
      before { global_store.set(key, value) }

      it 'should return the value of the specified key' do
        expect(subject.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'box' }

        it 'should return the value of the specified key' do
          expect(subject.get(key)).to eq(value)
        end
      end
    end

  end
end