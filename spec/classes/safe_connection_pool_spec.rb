require 'rspec'

module TieredCaching
  describe SafeConnectionPool do

    let(:connection) { double(:connection, call: nil) }
    let(:pool) { ConnectionPool.new { connection } }

    subject { SafeConnectionPool.new(pool) }

    describe '#with' do
      it 'should call the given block with the connection returned by the internal connection pool' do
        result_connection = subject.with { |conn| conn }
        expect(result_connection).to eq(connection)
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
      end
    end

  end
end