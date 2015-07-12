require 'rspec'

module TieredCaching
  describe HashStore do

    let(:hash) { {} }
    let(:key) { :key }
    let(:value) { 'valuable' }
    subject { HashStore.new(hash) }

    describe '#set' do
      it 'should set the underlying key-value pair of the internal hash' do
        subject.set(key, value)
        expect(hash[key]).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'cork' }
        let(:value) { :bottle }

        it 'should set the underlying key-value pair of the internal hash' do
          subject.set(key, value)
          expect(hash[key]).to eq(value)
        end
      end
    end

    describe '#get' do
      before { hash[key] = value }

      it 'should return the value of the underlying hash object' do
        expect(subject.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'cork' }
        let(:value) { :bottle }

        it 'should return the value of the underlying hash object' do
          expect(subject.get(key)).to eq(value)
        end
      end
    end

    it_behaves_like 'a store'

    it_behaves_like 'a store that deletes keys'

  end
end