require 'rspec'

module TieredCaching
  describe CacheMaster do
    let(:cache_line) { CacheMaster }

    it_behaves_like 'a tiered cache'
  end
end