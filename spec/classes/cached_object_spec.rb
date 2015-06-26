require 'rspec'

module TieredCaching
  describe CachedObject do

    class MockObject
      include CachedObject
    end

    class OtherMockObject
      include CachedObject
    end

    subject { MockObject }

    before { CacheMaster << global_store }

    describe '.[]' do
      let(:key) { 'key' }
      let(:object) { subject.new }

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

  end
end