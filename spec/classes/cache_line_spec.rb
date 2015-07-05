require 'rspec'

module TieredCaching
  describe CacheLine do
    let(:cache_line_name) { :base_line }
    let(:cache_line) { CacheLine.new(cache_line_name) }

    it_behaves_like 'a tiered cache'
  end
end