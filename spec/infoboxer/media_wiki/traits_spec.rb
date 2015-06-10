# encoding: utf-8
module Infoboxer
  describe MediaWiki::Traits do
    before do
      described_class.selectors.clear
      described_class.templates.clear
      described_class.domains.clear
    end
    
    describe 'definition' do
      let(:klass){Class.new(MediaWiki::Traits)}
      let(:traits){klass.new}
      
      describe 'selectors' do
        before{
          klass.selector :categories, Wikilink, namespace: 'Category'
        }
        it 'should return selectors' do
          expect(traits.selector(:categories)).to eq \
            Node::Selector.new(Wikilink, namespace: 'Category')
        end

        describe 'select from node' do
          let(:doc){Parser.paragraphs('Some text with [[Link]] and [[Category:Test]]')}
          subject{traits.lookup(:categories, doc)}

          it{should == [Wikilink.new('Category:Test')]}
        end
      end

      describe 'expand templates' do
        context 'when expandes to text' do
          before{
            klass.template('!'){'|'}
          }
          let(:template){Template.new('!')}
          subject{traits.expand(template)}
          it{should == Text.new('|')}
        end

        context 'when expandes to some nodes' do
          before{
            klass.template('replaceme'){|t| t.variables[1]}
          }
          let(:template){
            Parser.inline("{{replaceme|some ''text''}}").first
          }
          subject{traits.expand(template)}
          it{should == [Text.new('some '), Italic.new(Text.new('text'))]}
        end

        context 'when undefined template' do
          let(:template){Template.new('test')}
          subject{traits.expand(template)}
          
          it{should be_a(Template)}
          its(:name){should == 'test'}
        end

        describe 'definition helpers' do
          before{
            klass.templates_text(
              '!' => '|',
              ',' => '·'
            )
            klass.templates_unwrap('replaceme', 'replacehim')
          }

          context 'text replacements' do
            let(:template){Template.new('!')}
            subject{traits.expand(template)}
            it{should == Text.new('|')}
          end

          context 'unwrap (value of first variable) replacements' do
            let(:template){
              Parser.inline("{{replaceme|some ''text''}}").first
            }
            subject{traits.expand(template)}
            it{should == [Text.new('some '), Italic.new(Text.new('text'))]}
          end
        end
      end

      describe 'binding to domain' do
        before{
          klass.domain 'en.wikipedia.org'
        }
        subject{MediaWiki::Traits.get('en.wikipedia.org')}
        it{should be_a(klass)}

        context 'when non-bound domain' do
          subject{MediaWiki::Traits.get('fr.wikipedia.org')}
          it{should be_a(MediaWiki::Traits)}
        end
      end

      describe 'on-the-fly enrichment' do
        before{
          klass.domain 'en.wikipedia.org'
        }
        subject{MediaWiki::Traits.get('en.wikipedia.org', file_prefix: 'File')}
        its(:file_prefix){should == ['File']}
      end
    end
  end
end
