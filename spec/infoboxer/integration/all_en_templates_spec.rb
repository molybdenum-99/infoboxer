# encoding: utf-8

module Infoboxer
  describe 'en.wikipedia.org', :vcr do
    let(:page) { Infoboxer.wp.get('Chile') }
    subject {
      page.infobox
          .fetch('leader_name1')
          .lookup(:Wikilink).first.link
    }
    it { is_expected.to eq 'Michelle Bachelet' }
  end
end
