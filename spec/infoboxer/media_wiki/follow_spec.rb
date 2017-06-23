# encoding: utf-8

module Infoboxer
  describe Tree::Wikilink do
    let(:source) {
      VCR.use_cassette('follow-source-argentine') {
        Infoboxer.wp.get('Argentina')
      }}
    let(:link) { source.lookup(:Wikilink, link: 'Chile').first }

    describe :url do
      subject { link.url }

      it { is_expected.to eq 'https://en.wikipedia.org/wiki/Chile' }
    end

    describe :follow do
      subject { VCR.use_cassette('follow-chile') { link.follow } }

      it { is_expected.to be_a(MediaWiki::Page) }
      its(:title) { is_expected.to eq 'Chile' }
      its(:text) { is_expected.to include('The arid Atacama Desert in northern Chile contains great mineral wealth, principally copper.') }
    end
  end

  describe Tree::Nodes, :follow do
    let(:source) {
      VCR.use_cassette('follow-source-argentine2') {
        Infoboxer.wp.get('Argentina')
      }}
    let(:links) { source.lookup(:Wikilink).first(3) }

    subject { VCR.use_cassette('follow-several') { links.follow } }

    it { is_expected.to be_a(Tree::Nodes) }
    it { is_expected.to all(be_a(MediaWiki::Page)) }
  end

  describe 'Template#follow' do
    let(:source) {
      VCR.use_cassette('follow-source-forests') {
        Infoboxer.wp.get('Tropical and subtropical coniferous forests')
      }}
    let(:template) { source.templates(name: /forests$/).first }

    describe :url do
      subject { template.url }

      it { is_expected.to eq 'https://en.wikipedia.org/wiki/Template:Indomalaya_tropical_and_subtropical_coniferous_forests' }
    end

    describe :follow do
      subject { VCR.use_cassette('follow-template') { template.follow } }

      it { is_expected.to be_a(MediaWiki::Page) }
      its(:url) { is_expected.to eq 'https://en.wikipedia.org/wiki/Template:Indomalaya_tropical_and_subtropical_coniferous_forests' }
    end
  end
end
