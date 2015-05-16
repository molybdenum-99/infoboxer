# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser do
    def parse(text)
      described_class.new(text).parse
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

    describe 'simple inline markup' do
      def parse_inline(text)
        described_class.new(text).parse_inline
      end

      describe 'one item' do
        subject{parse_inline(source).children.first}

        context 'when just text' do
          let(:source){'just text'}
          
          it{should be_a(Parser::Text)}
          its(:text){should == 'just text'}
        end
      end

      describe 'sequence' do
      end

      describe 'nesting' do
      end

      describe 'nesting in para' do
      end

      describe 'leaving alone the <pre>' do
      end
    end

    describe 'templates' do
    end

    describe 'tables' do
    end

    describe 'special document nodes' do
    end
  end
end
