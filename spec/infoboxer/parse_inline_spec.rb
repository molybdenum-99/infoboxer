# encoding; utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser::InlineParser do
    def parse_inline(text)
      described_class.new(text).parse
    end

    describe 'simple inline markup' do
      describe 'one item' do
        subject{parse_inline(source).first}

        context 'when just text' do
          let(:source){'just text'}
          
          it{should be_a(Parser::Text)}
          its(:text){should == 'just text'}
        end

        context 'text with entities' do
          let(:source){'just textin&apos; with &Omega; symbol'}

          its(:text){should == "just textin' with \u{03A9} symbol"}
        end

        context 'when italic' do
          let(:source){"''italic''"}
          
          it{should be_a(Parser::Italic)}
          its(:text){should == 'italic'}
        end

        context 'when bold' do
          let(:source){"'''bold'''"}
          
          it{should be_a(Parser::Bold)}
          its(:text){should == 'bold'}
        end

        context 'when bold italic' do
          let(:source){"'''''bold italic'''''"}
          
          it{should be_a(Parser::BoldItalic)}
          its(:text){should == 'bold italic'}
        end

        context 'when wikilink' do
          context 'with label' do
            let(:source){'[[Argentina|Ar]]'}

            it{should be_a(Parser::Wikilink)}
            its(:link){should == 'Argentina'}
            its(:label){should == 'Ar'}
          end

          context 'without caption' do
            let(:source){'[[Argentina]]'}

            it{should be_a(Parser::Wikilink)}
            its(:link){should == 'Argentina'}
            its(:label){should == 'Argentina'}
          end
        end

        context 'when external link' do
          context 'with label' do
            let(:source){'[http://google.com Google]'}

            it{should be_a(Parser::ExternalLink)}
            its(:link){should == 'http://google.com'}
            its(:label){should == 'Google'}
          end

          context 'without caption' do
            let(:source){'[http://google.com]'}

            it{should be_a(Parser::ExternalLink)}
            its(:link){should == 'http://google.com'}
            its(:label){should == 'http://google.com'}
          end
        end

        context 'when HTML' do
          context 'paired' do
            let(:source){'<strike>Some text</strike>'}

            it{should be_a(Parser::HTMLTag)}
            its(:tag){should == 'strike'}
            its(:text){should == 'Some text'}
          end

          context 'self-closing' do
            let(:source){'<br/>'}

            it{should be_a(Parser::HTMLTag)}
            its(:tag){should == 'br'}
            its(:text){should == ''}
          end

          context 'lonely opening' do
            let(:source){'<strike>Some text'}

            it{should be_a(Parser::HTMLOpeningTag)}
            its(:tag){should == 'strike'}
          end

          context 'lonely closing' do
            let(:source){'</strike>'}

            it{should be_a(Parser::HTMLClosingTag)}
            its(:tag){should == 'strike'}
          end
        end

        # TODO: check what we do with incorrect markup
      end

      describe 'sequence' do
        let(:source){"This is '''bold''' text with [[Some link|Link]]"}
        subject{parse_inline(source)}

        it 'should be parsed!' do
          expect(subject.count).to eq 4
          expect(subject.map(&:class)).to eq [Parser::Text, Parser::Bold, Parser::Text, Parser::Wikilink]
          expect(subject.map(&:text)).to eq ['This is ', 'bold', ' text with ', 'Link']
        end
      end

      describe 'nesting' do
        let(:source){"'''[[Bold link|Link]]'''"}
        subject{parse_inline(source).first}

        it{should be_kind_of(Parser::Bold)}
        its(:"children.first"){should be_kind_of(Parser::Wikilink)}
      end
    end

    describe 'inline markup spanning for several lines' do
    end
  end
end
