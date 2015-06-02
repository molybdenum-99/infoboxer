# encoding: utf-8
module Infoboxer
  describe 'Integration of MediaWiki::Context into data' do
    describe 'template expansion on-the-fly' do
      let(:klass){
        Class.new(MediaWiki::Context) do
          templates_text(
            '!' => '|',
            ',' => '·'
          )
          template('join'){|t| Nodes[*t.variables.values]}
        end
      }
      let(:ctx){klass.new}
      let(:nodes){
        Parser::InlineParser.parse(source, [], ctx)
      }

      context 'when simple nested templates' do
        let(:source){
          "before {{join|{{!}} text|and ''italics''}} after"
        }

        subject{
          nodes
        }

        it{should == [
          Text.new('before '),
          Text.new('|'),
          Text.new(' text'),
          Text.new('and '),
          Italic.new(Text.new('italics')),
          Text.new(' after')
        ]}
      end
      
      context 'when multiline templates' do
        let(:source){
          "{{unknown|{{!}}\n\ntext\n\n{{,}}}}r"
        }
        subject{nodes.first.variables[1]}
        it{should == [
          Paragraph.new(Text.new('|')),
          Paragraph.new(Text.new('text')),
          Paragraph.new(Text.new('·')),
        ]}
      end

      context 'when templates in image or link captions' do
      end

      context 'when templates in tables' do
      end
    end

    describe 'context-dependent navigation' do
    end

    describe 'context selection by client' do
    end
  end
end
