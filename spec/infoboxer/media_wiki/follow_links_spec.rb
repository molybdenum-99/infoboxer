# encoding: utf-8
module Infoboxer
  describe 'Wikilink#follow' do
    let(:source){VCR.use_cassette('follow-source-argentine'){
      Infoboxer.wp.get('Argentina')
    }}
    let(:link){source.lookup(:Wikilink, link: 'Chile').first}
    
    subject{VCR.use_cassette("follow-chile"){link.follow}}
    it{should be_a(Page)}
    its(:title){should == 'Chile'}
    its(:text){should include('The arid Atacama Desert in northern Chile contains great mineral wealth, principally copper.')}
  end

  describe 'Nodes#follow' do
    let(:source){VCR.use_cassette('follow-source-argentine2'){
      Infoboxer.wp.get('Argentina')
    }}
    let(:links){source.lookup(:Wikilink).first(3)}
    
    subject{VCR.use_cassette("follow-several"){links.follow}}
    it{should be_a(Tree::Nodes)}
    it{should all(be_a(Page))}
  end
end
