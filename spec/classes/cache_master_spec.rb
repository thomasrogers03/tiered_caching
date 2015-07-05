require 'rspec'

module TieredCaching
  describe CacheMaster do
    let(:cache_line) { CacheMaster }
    let(:cache_line_name) { 'CacheMaster' }

    it_behaves_like 'a tiered cache'

    context 'with a different cache line' do
      let(:cache_line_name) { :line_two }
      let(:cache_line) { CacheMaster[cache_line_name] }

      it_behaves_like 'a tiered cache'
    end
  end
end