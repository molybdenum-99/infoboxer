# encoding: utf-8
module Infoboxer
  describe MediaWiki::Context do
    before do
      described_class.selectors.clear
      described_class.templates.clear
      described_class.domains.clear
    end
    
    describe 'definition' do
      let(:klass){Class.new(MediaWiki::Context)}
      let(:ctx){klass.new}
      
      describe 'selectors' do
        before{
          klass.selector :categories, Wikilink, namespace: 'Category'
        }
        it 'should return selectors' do
          expect(ctx.selector(:categories)).to eq \
            Node::Selector.new(Wikilink, namespace: 'Category')
        end

        describe 'select from node' do
          let(:doc){Parser.parse('Some text with [[Link]] and [[Category:Test]]')}
          subject{ctx.lookup(:categories, doc)}

          it{should == [Wikilink.new('Category:Test')]}
        end
      end

      describe 'expand templates' do
        context 'when expandes to text' do
          before{
            klass.template('!'){'|'}
          }
          let(:template){Template.new('!')}
          subject{ctx.expand(template)}
          it{should == Text.new('|')}
        end

        context 'when expandes to some nodes' do
          before{
            klass.template('replaceme'){|t| t.variables[1]}
          }
          let(:template){
            Parser::InlineParser.parse("{{replaceme|some ''text''}}").first
          }
          subject{ctx.expand(template)}
          it{should == [Text.new('some '), Italic.new(Text.new('text'))]}
        end

        context 'when undefined template' do
          let(:template){Template.new('test')}
          subject{ctx.expand(template)}
          
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
            subject{ctx.expand(template)}
            it{should == Text.new('|')}
          end

          context 'unwrap (value of first variable) replacements' do
            let(:template){
              Parser::InlineParser.parse("{{replaceme|some ''text''}}").first
            }
            subject{ctx.expand(template)}
            it{should == [Text.new('some '), Italic.new(Text.new('text'))]}
          end
        end
      end

      describe 'binding to domain' do
        before{
          klass.domain 'en.wikipedia.org'
        }
        subject{MediaWiki::Context.get('en.wikipedia.org')}
        it{should be_a(klass)}

        context 'when non-bound domain' do
          subject{MediaWiki::Context.get('fr.wikipedia.org')}
          it{should be_nil}
        end
      end
    end
  end
end
