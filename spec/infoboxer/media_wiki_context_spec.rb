# encoding: utf-8
module Infoboxer
  describe MediaWiki::Context do
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

      describe 'substitutions' do
        context 'when subsitutes with text' do
          before{
            klass.template('!'){'|'}
          }
          let(:template){Template.new('!')}
          subject{ctx.substitute(template)}
          it{should == Text.new('|')}
        end

        context 'when substitutes with parsed nodes' do
          before{
            klass.template('replaceme'){|t| t.variables[1]}
          }
          let(:template){
            Parser::InlineParser.parse("{{replaceme|some ''text''}}").first
          }
          subject{ctx.substitute(template)}
          it{should == [Text.new('some '), Italic.new(Text.new('text'))]}
        end

        context 'when undefined template' do
          let(:template){Template.new('test')}
          subject{ctx.substitute(template)}
          
          it{should be_a(Template)}
          its(:name){should == 'test'}
        end

        describe 'definition helpers' do
        end
      end

      describe 'binding' do
      end
    end
  end
end
