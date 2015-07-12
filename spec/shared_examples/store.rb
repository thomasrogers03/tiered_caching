module TieredCaching

  shared_examples_for 'a store' do
    let(:key) { 'key' }
    let(:value) { 'value' }

    describe '#getset' do
      it 'should return the specified value' do
        expect(subject.getset(key) { value }).to eq(value)
      end

      it 'should save the key-value pair if not already existing' do
        subject.getset(key) { value }
        expect(subject.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }
        let(:value) { 'door' }

        it 'should return the specified value' do
          expect(subject.getset(key) { value }).to eq(value)
        end

        it 'should save the key-value pair if not already existing' do
          subject.getset(key) { value }
          expect(subject.get(key)).to eq(value)
        end
      end

      context 'when the value is already set' do
        let(:previous_value) { 'different value' }

        before { subject.set(key, previous_value) }

        it 'should return the specified value' do
          expect(subject.getset(key) { value }).to eq(previous_value)
        end

        it 'should not over-write an existing value' do
          subject.getset(key) { value }
          expect(subject.get(key)).to eq(previous_value)
        end
      end

    end
  end

end