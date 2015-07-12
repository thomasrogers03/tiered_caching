module TieredCaching

  shared_examples_for 'a store that deletes keys' do
    before { allow(Logging.logger).to receive(:warn) }

    describe '#delete' do
      it 'should delete the item from the store' do
        subject.set('key', 'value')
        subject.delete('key')
        expect(subject.get('key')).to be_nil
      end

      context 'with a different key-value pair' do
        it 'should delete the item from the store' do
          subject.set('lock', 'door')
          subject.delete('lock')
          expect(subject.get('lock')).to be_nil
        end
      end
    end

    describe '#clear' do
      let(:attributes) do
        10.times.inject({}) do |memo|
          memo.merge!(SecureRandom.uuid => SecureRandom.uuid)
        end
      end

      before { attributes.each { |key, value| subject.set(key, value) } }

      it 'should delete all keys from the store' do
        subject.clear
        values = attributes.keys.map { |key| subject.get(key) }.compact
        expect(values).to be_empty
      end
    end
  end

end