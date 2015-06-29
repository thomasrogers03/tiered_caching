require 'rspec'

module TieredCaching
  describe SafeConnectionPool do

    let(:connection) { double(:connection, call: nil) }
    let(:recovery_callback) { ->(pool) {} }
    let(:pool) { ConnectionPool.new { connection } }

    subject { SafeConnectionPool.new(pool, &recovery_callback) }

    describe '#with' do
      it 'should call the given block with the connection returned by the internal connection pool' do
        result_connection = subject.with { |conn| conn }
        expect(result_connection).to eq(connection)
      end

      it 'should leave the pool in a good state' do
        subject.with {}
        expect(subject.disabled?).to eq(false)
      end

      context 'with a different block' do
        it 'should return the result of that block' do
          result = subject.with { 135 }
          expect(result).to eq(135)
        end
      end

      context 'with an error' do
        it 'should return nil' do
          result = subject.with { raise 'It blew up!' }
          expect(result).to be_nil
        end

        it 'should call the recovery callback' do
          expect(recovery_callback).to receive(:call).with(subject)
          subject.with { raise 'It blew up!' }
        end

        it 'should put the pool in a bad state' do
          subject.with { raise 'It blew up!' }
          expect(subject.disabled?).to eq(true)
        end

        it 'should return nil for all further requests' do
          subject.with { raise 'It blew up!' }
          result = subject.with { 157 }
          expect(result).to be_nil
        end
      end
    end

    describe '#enable!' do
      it 'should re-enable a disabled pool' do
        subject.with { raise 'It blew up!' }
        subject.enable!
        expect(subject.disabled?).to eq(false)
      end
    end

  end
end