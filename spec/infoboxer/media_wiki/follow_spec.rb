module Infoboxer
  describe Tree::Wikilink, :vcr do
    let(:source) { Infoboxer.wp.get('Argentina') }
    let(:link) { source.lookup(:Wikilink, link: 'Chile').first }

    describe :url do
      subject { link.url }

      it { is_expected.to eq 'https://en.wikipedia.org/wiki/Chile' }
    end

    describe :follow do
      subject { link.follow }

      it { is_expected.to be_a(MediaWiki::Page) }
      its(:title) { is_expected.to eq 'Chile' }
      its(:text) { is_expected.to include('The arid Atacama Desert in northern Chile contains great mineral wealth, principally copper.') }

      context 'when interwiki link' do
        let(:source) { Infoboxer.wp.get('List of kanji by concept') }
        let(:link) { source.lookup(:Wikilink, interwiki: 'wikt').first }

        subject { link.follow }

        it { is_expected.to be_a(MediaWiki::Page) }
        its(:url) { is_expected.to include 'wiktionary' }
      end
    end
  end

  describe Tree::Nodes, :follow, :vcr do
    let(:source) { Infoboxer.wp.get('Argentina') }
    let(:links) { source.lookup(:Wikilink).first(3) }

    subject { links.follow }

    it { is_expected.to be_a(Tree::Nodes) }
    it { is_expected.to all(be_a(MediaWiki::Page)) }

    context 'when interwiki link' do
      let(:source) { Infoboxer.wp.get('List of kanji by concept') }
      let(:link1) { source.lookup(:Wikilink, interwiki: 'wikt').first }
      let(:link2) { source.lookup(:Wikilink, interwiki: nil).first }
      let(:links) { Tree::Nodes[link1, link2] }

      subject { links.follow }

      it { is_expected.to be_a(Tree::Nodes).and all(be_a(MediaWiki::Page)) }
      its_map(:url) { is_expected.to contain_exactly(include('wiktionary'), include('wikipedia')) }
    end
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
