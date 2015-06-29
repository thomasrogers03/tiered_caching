require 'rspec'

module TieredCaching
  describe AsyncStore do

    let(:mock_store) { double(:store) }
    let(:pool) { ConnectionPool.new(size: 1) { mock_store } }
    let(:executor) { StoreHelpers::MockExecutor.new }
    let(:key) { 'key' }
    let(:value) { 'value' }

    subject { AsyncStore.new(pool, executor) }

    before { executor.reset! }

    describe '#set' do
      after { executor.call }

      it 'should call #set on the underlying store using a separate thread' do
        subject.set(key, value)
        expect(mock_store).to receive(:set).with(key, value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'box' }

        it 'should call #set on the underlying store using a separate thread' do
          subject.set(key, value)
          expect(mock_store).to receive(:set).with(key, value)
        end
      end

    end

  end
end