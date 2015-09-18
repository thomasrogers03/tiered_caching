require 'rspec'

module TieredCaching
  describe CachedObject do

    class MockObject
      include CachedObject

      def self.reset!
        @attributes = nil
      end
    end

    class OtherMockObject
      include CachedObject
    end

    let(:key) { 'key' }
    let(:object) { subject.new }
    let(:cache_line) { nil }
    let(:cache_store) { global_store }

    subject { MockObject }

    before do
      MockObject.reset!
      subject.cache_line = cache_line
      CacheMaster[cache_line] << cache_store
      allow(Logging.logger).to receive(:warn)
    end

    describe '.[]' do
      it 'should retrieve the object from the CacheMaster' do
        CacheMaster.set(class: MockObject, key: key) { object }
        expect(subject[key]).to eq(object)
      end

      context 'with a different key' do
        let(:key) { 'other key' }

        it 'should retrieve the object from the CacheMaster' do
          CacheMaster.set(class: MockObject, key: key) { object }
          expect(subject[key]).to eq(object)
        end
      end

      context 'with mixed key encodings using a serializing store' do
        let(:cache_store) { global_serializing_store }

        it 'should normalized the requested key to UTF-8' do
          CacheMaster.set(class: MockObject, key: key.encode('UTF-8')) { object }
          expect(subject[key.encode('US-ASCII')]).to eq(object)
        end
      end

      context 'with a different class' do
        subject { OtherMockObject }

        it 'should retrieve the object from the CacheMaster' do
          CacheMaster.set(class: OtherMockObject, key: key) { object }
          expect(subject[key]).to eq(object)
        end
      end

      context 'when a .on_missing method is defined' do
        before do
          MockObject.on_missing { |key| "computed value from #{key}" }
        end

        it 'should be the return value of that block' do
          expect(MockObject[key]).to eq('computed value from key')
        end

        it 'should cache that value' do
          MockObject[key]
          MockObject.on_missing { nil }
          expect(MockObject[key]).to eq('computed value from key')
        end

        context 'with a different key' do
          let(:key) { 'different key' }

          it 'should be the return value of that block computed with the key' do
            expect(MockObject[key]).to eq('computed value from different key')
          end
        end
      end
    end

    describe '.[]=' do
      it 'should save the object using the class and specified key as the CacheMaster key' do
        subject[key] = object
        expect(CacheMaster.get(class: MockObject, key: key)).to eq(object)
      end

      context 'with mixed key encodings using a serializing store' do
        let(:cache_store) { global_serializing_store }

        it 'should normalized the requested key to UTF-8' do
          subject[key.encode('US-ASCII')] = object
          expect(CacheMaster.get(class: MockObject, key: key.encode('UTF-8'))).to eq(object)
        end
      end

      context 'with a different key' do
        let(:key) { 'other key' }

        it 'should cache the object' do
          subject[key] = object
          expect(CacheMaster.get(class: MockObject, key: key)).to eq(object)
        end
      end

      context 'with a different class' do
        subject { OtherMockObject }

        it 'should cache the object' do
          subject[key] = object
          expect(CacheMaster.get(class: OtherMockObject, key: key)).to eq(object)
        end
      end

      context 'with a different cache line' do
        let(:cache_line) { :fast_line }

        it 'should cache the object' do
          subject[key] = object
          expect(CacheMaster[cache_line].get(class: MockObject, key: key)).to eq(object)
        end
      end

      context 'with the wrong type of object specified' do
        it 'should raise an error' do
          expect { subject[key] = 'bad type' }.to raise_error(TypeError, 'Cannot convert String into TieredCaching::MockObject')
        end

        context 'with a different type combination' do
          subject { OtherMockObject }

          it 'should raise an error' do
            expect { subject[key] = 1337 }.to raise_error(TypeError, 'Cannot convert Fixnum into TieredCaching::OtherMockObject')
          end
        end
      end
    end

    describe '.delete' do
      let(:key) { 'key' }

      before { subject['key'] = object }

      it 'should delete the item from the store' do
        subject.delete(key)
        expect(subject[key]).to be_nil
      end

      context 'with a different key-value pair' do
        let(:key) { 'lock' }

        it 'should delete the item from the store' do
          subject.delete(key)
          expect(subject[key]).to be_nil
        end
      end

      context 'with a different cache line' do
        let(:cache_line) { :fast_line }

        it 'should cache the object' do
          subject.delete(key)
          expect(CacheMaster[cache_line].get(class: MockObject, key: key)).to be_nil
        end
      end
    end

    describe '#save_to_cache' do
      it 'should save the object to cache using the specified key' do
        object.save_to_cache(key)
        expect(subject[key]).to eq(object)
      end

      context 'with mixed key encodings using a serializing store' do
        let(:cache_store) { global_serializing_store }

        it 'should normalized the requested key to UTF-8' do
          object.save_to_cache(key.encode('US-ASCII'))
          expect(subject[key.encode('BINARY')]).to eq(object)
        end
      end

      context 'with a different key' do
        let(:key) { 'other key' }

        it 'should save the object to cache using the specified key' do
          object.save_to_cache(key)
          expect(subject[key]).to eq(object)
        end
      end

      context 'with a different type' do
        subject { OtherMockObject }

        it 'should save the object to cache using the right type' do
          object.save_to_cache(key)
          expect(subject[key]).to eq(object)
        end
      end
    end

  end
end
