require 'rspec'

module TieredCaching
  describe CacheMaster do
    let(:cache_line) { CacheMaster }
    let(:cache_line_name) { cache_line }

    it_behaves_like 'a tiered cache'
  end
end