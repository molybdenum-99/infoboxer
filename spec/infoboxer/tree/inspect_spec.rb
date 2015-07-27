# encoding: utf-8
module Infoboxer
  module Tree
    describe Node, :inspect do
      subject{node.inspect}

      describe Node do
        context 'by default' do
          let(:node){Node.new(level: 3, class: 'red')}

          it{should == '#<Node(level: 3, class: "red")>'}
        end
      end
      
      describe Text do
        context 'by default' do
          let(:node){Text.new('some text')}
          
          it{should == '#<Text: some text>'}
        end

        context 'really long text' do
          let(:str){'some text'*100}
          let(:node){Text.new(str)}
          
          it{should == "#<Text: #{str[0..30]}...>"}
        end
      end

      describe Compound do
        context 'children' do
          let(:node){Compound.new([Text.new('one'), Text.new('two')])}

          it{should == '#<Compound: onetwo>'}
        end

        context 'long children list' do
          let(:node){Compound.new([
            Text.new('one long sentence'),
            Text.new('two long sentences'),
            Text.new('three long sentences'),
            Text.new('four long sentences'),
            Text.new('five')])}

          it{should == '#<Compound: one long sentencetwo long sente...>'}
        end

        context 'complex children' do
          let(:node){Compound.new([Italic.new(Text.new('one')), Italic.new(Bold.new(Text.new('two')))])}

          it{should ==
            '#<Compound: onetwo>'
          }
        end
      end

      describe Template do
        context 'default' do
          let(:node){Template.new('test')}

          it{should == '#<Template[test]>'}
        end

        context 'with param-ish variables' do
          let(:node){Template.new('test', Nodes[TemplateVariable.new('foo', Text.new('var'))])}

          it{should == '#<Template[test](foo: "var")>'}
        end

        context 'many variables' do
          let(:source){ File.read('spec/fixtures/large_infobox.txt') }
          let(:node){Parser.inline(source).first}

          it{should include('#<Template[Infobox country](common_name: "Argentina"')}
        end
      end

      describe InFlowTemplate do
      end

      describe Page, :vcr do
        let(:node){Infoboxer.wikipedia.get('Argentina')}
        it{should match \
          %r{^\#<Page\(title: "Argentina", url: "https://en.wikipedia.org/wiki/Argentina"\): [^<]{,31}\.\.\.>$}
        }
      end
    end
  end
end
