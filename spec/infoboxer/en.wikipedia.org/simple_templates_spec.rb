# encoding: utf-8
module Infoboxer
  describe 'simple templates definitions' do
    let(:traits){MediaWiki::Traits.get('en.wikipedia.org')}

    def parse(wikitext)
      Parser.inline(wikitext, traits)
    end
    
    def w2t(wikitext)
      parse(wikitext).text
    end
    
    describe 'literal templates' do
      it 'should leave them as is' do
        expect(w2t('A {{&}} B is {{1/2}}')).to eq 'A & B is 1/2'
      end
    end

    describe 'inflow templates' do
      it 'should leave inside text' do
        expect(w2t('A {{nowrap|wtf}} B')).to eq 'A wtf B'
      end

      it 'should be inside-navigable' do
        expect(parse('{{nowrap|[[Chile]]}}').lookup(:Wikilink).first.link).to eq 'Chile'
      end
    end

    describe 'templates with additional methods' do
      it 'should calculate' do
        expect(parse('{{Infobox country}}').lookup(:infobox?).count).to eq 1
      end
    end
  end
end
