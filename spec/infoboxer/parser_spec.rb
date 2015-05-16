# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser do
    def parse(text)
      described_class.parse(text)
    end
    
    describe 'basics' do
      subject{parse('just text')}

      it{should be_an(Parser::Document)}
      its(:children){should be_a(Parser::Nodes)}
    end

    describe 'paragraphs' do
      describe 'one item' do
        subject{parse(source).children.first}

        context 'just a para' do
          let(:source){'some text'}
          
          it{should be_a(Parser::Paragraph)}
          its(:text){should == 'some text'}
        end

        context 'header' do
          let(:source){'== Some text'}
          
          it{should be_a(Parser::Heading)}
          its(:text){should == 'Some text'}
          its(:level){should == 2}
        end

        context 'list item' do
          let(:source){'*Some text'}
          
          it{should be_a(Parser::ListItem)}
          its(:text){should == 'Some text'}

          # TODO: different markers and item levels spec!
        end

        context 'hr' do
          let(:source){'--------------'}
          
          it{should be_a(Parser::HR)}
        end

        context 'pre' do
          let(:source){' i += 1'}
          
          it{should be_a(Parser::Pre)}
          its(:text){should == 'i += 1'}
        end
      end

      describe 'sequence' do
        subject{parse(source).children}

        let(:source){ "== Heading\nParagraph\n*List item"}

        its(:count){should == 3}
        it 'should be correct items' do
          expect(subject.map(&:class)).to eq [Parser::Heading, Parser::Paragraph, Parser::ListItem]
          expect(subject.map(&:text)).to eq ['Heading', 'Paragraph', 'List item']
        end
      end

      describe 'merging subsequent' do
        subject{parse(source).children}

        context 'paragraphs' do
          let(:source){"First para\nStill first\n\nNext para"}

          its(:count){should == 2}
          it 'should be only two of them' do
            # Fixme: should be "First para Still first"
            expect(subject.map(&:text)).to eq ["First paraStill first", "Next para"]
          end
        end

        context 'not mergeable' do
          let(:source){"== First heading\n== Other heading"}

          its(:count){should == 2}
        end
        
        context 'list'
      end
    end

    describe 'parsing inline content' do
      let(:source){"Paragraph '''with''' [[link]]\n== Heading"}
      subject{parse(source).children.first}

      it{should be_a(Parser::Paragraph)}
      it 'should be cool' do
        expect(subject.children.map(&:class)).to eq \
          [Parser::Text, Parser::Bold, Parser::Text, Parser::Wikilink]
        
        expect(subject.children.map(&:text)).to eq \
          ['Paragraph ', 'with', ' ', 'link']
      end
    end

    describe 'tables' do
      let(:source){"Paragraph, then table:\n{|\n|one||two\n|}"}
      subject{parse(source).children}

      it 'should work' do
        expect(subject.map(&:class)).to eq [Parser::Paragraph, Parser::Table]
      end
    end

    describe 'special document nodes' do
    end
  end
end
