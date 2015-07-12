require 'rspec'

module TieredCaching
  describe SerializingStore do

    let(:key) { :key }
    let(:value) { :value }
    let(:serialized_key) { Digest::MD5.hexdigest(Marshal.dump(key)) }
    let(:serialized_value) { Marshal.dump(value) }

    subject { SerializingStore.new(global_store) }

    describe '#set' do
      it 'should save the serialized key-value pair to the underlying store' do
        subject.set(key, value)
        expect(global_store.get(serialized_key)).to eq(serialized_value)
      end

      context 'with a different key-value pair' do
        let(:key) { :car }
        let(:value) { :brake }

        it 'should save the serialized key-value pair to the underlying store' do
          subject.set(key, value)
          expect(global_store.get(serialized_key)).to eq(serialized_value)
        end
      end
    end

    describe '#get' do
      before { global_store.set(serialized_key, serialized_value) }

      it 'should return the deserialized value for the given key' do
        expect(subject.get(key)).to eq(value)
      end

      context 'with a different key-value pair' do
        let(:key) { :car }
        let(:value) { :brake }

        it 'should return the deserialized value for the given key' do
          expect(subject.get(key)).to eq(value)
        end
      end

      context 'when the value does not exist' do
        before { global_store.set(serialized_key, nil) }

        it 'should return the deserialized value for the given key' do
          expect(subject.get(key)).to be_nil
        end
      end
    end

    it_behaves_like 'a store'

    it_behaves_like 'a store that deletes keys'

  end
end