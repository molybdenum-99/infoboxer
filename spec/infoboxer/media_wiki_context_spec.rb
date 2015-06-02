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
      end

      describe 'binding' do
      end
    end
  end
end
