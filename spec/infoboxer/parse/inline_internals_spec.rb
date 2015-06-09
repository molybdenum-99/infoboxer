# encoding: utf-8
module Infoboxer
  describe Parse::InlineParser do
    describe :parse_until do
      let(:source){"thumb|200px|The [[Cueva de las Manos|Cave of the Hands]] in ]]"}
      let(:ctx){Parse::Context.new(source)}
      let(:parser){Parse::InlineParser.new(ctx)}

      it 'should be decent' do
        expect(parser.parse_until(/\||\]\]/).text).to eq 'thumb'
        expect(ctx.rest).to eq "200px|The [[Cueva de las Manos|Cave of the Hands]] in ]]"
      end

      context 'when allow paragraphs' do
        let(:source){"thumb\n* nail|200px|The [[Cueva de las Manos|Cave of the Hands]] in ]]"}
        let(:nodes){parser.parse_until_with_p(/\||\]\]/)}

        it 'should be smart' do
          expect(nodes.map(&:class)).to eq [Text, UnorderedList]
          expect(ctx.rest).to eq "200px|The [[Cueva de las Manos|Cave of the Hands]] in ]]"
        end
      end

      context 'several lines with templates and html' do
        let(:source){
          "Argentine diplomatic missions:\n"\
          "<div style=\"font-size:90%;\">\n"\
          "{{legend4|#22b14c|Argentina}}\n"\
          "{{legend4|#2f3699|Nations hosting a resident diplomatic mission}}\n"\
          "{{legend4|#b9b9b9|Nations without a resident diplomatic mission}}\n"\
          "</div>]]"
        }
        let(:nodes){parser.parse_until_with_p(/\||\]\]/)}
        it 'should grab templates and other stuff' do
          expect(nodes.map(&:class)).to eq [Text, Paragraph]
          expect(nodes.last.children.map(&:class)).to eq [HTMLOpeningTag, Text, Template, Text, Template, Text, Template, Text, HTMLClosingTag]
          expect(ctx.matched).to eq ']]'
        end
      end
    end
  end
end
