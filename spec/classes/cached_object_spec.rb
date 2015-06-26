require 'rspec'

module TieredCaching
  describe CachedObject do

    class MockObject
      include CachedObject
    end

    class OtherMockObject
      include CachedObject
    end

    let(:key) { 'key' }
    let(:object) { subject.new }

    subject { MockObject }

    before { CacheMaster << global_store }

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

      context 'with a different class' do
        subject { OtherMockObject }

        it 'should retrieve the object from the CacheMaster' do
          CacheMaster.set(class: OtherMockObject, key: key) { object }
          expect(subject[key]).to eq(object)
        end
      end
    end

    describe '.[]=' do
      it 'should save the object using the class and specified key as the CacheMaster key' do
        subject[key] = object
        expect(CacheMaster.get(class: MockObject, key: key)).to eq(object)
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

      context 'with the wrong type of object specified' do
        it 'should raise an error' do
          expect{subject[key] = 'bad type'}.to raise_error(TypeError, 'Cannot convert String into TieredCaching::MockObject')
        end

        context 'with a different type combination' do
          subject { OtherMockObject }

          it 'should raise an error' do
            expect{subject[key] = 1337}.to raise_error(TypeError, 'Cannot convert Fixnum into TieredCaching::OtherMockObject')
          end
        end
      end
    end

  end
end