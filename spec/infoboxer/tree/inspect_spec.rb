module Infoboxer
  module Tree
    describe Node, :inspect do
      subject { node.inspect }

      describe Node do
        context 'by default' do
          let(:node) { Node.new(level: 3, class: 'red') }

          it { is_expected.to eq '#<Node(level: 3, class: "red")>' }
        end
      end

      describe Text do
        context 'by default' do
          let(:node) { Text.new('some text') }

          it { is_expected.to eq '#<Text: some text>' }
        end

        context 'really long text' do
          let(:str) { 'some text' * 100 }
          let(:node) { Text.new(str) }

          it { is_expected.to eq "#<Text: #{str[0..30]}...>" }
        end
      end

      describe Compound do
        context 'children' do
          let(:node) { Compound.new([Text.new('one'), Text.new('two')]) }

          it { is_expected.to eq '#<Compound: onetwo>' }
        end

        context 'long children list' do
          let(:node) {
            Compound.new([
                           Text.new('one long sentence'),
                           Text.new('two long sentences'),
                           Text.new('three long sentences'),
                           Text.new('four long sentences'),
                           Text.new('five')
                         ])
          }

          it { is_expected.to eq '#<Compound: one long sentencetwo long sente...>' }
        end

        context 'complex children' do
          let(:node) { Compound.new([Italic.new(Text.new('one')), Italic.new(Bold.new(Text.new('two')))]) }

          it { is_expected.to eq '#<Compound: onetwo>' }
        end
      end

      describe Template do
        context 'default' do
          let(:node) { Template.new('test') }

          it { is_expected.to eq '#<Template[test]>' }
        end

        context 'with param-ish variables' do
          let(:node) { Template.new('test', Nodes[Var.new('foo', Text.new('var'))]) }

          it { is_expected.to eq '#<Template[test](foo: "var")>' }
        end

        context 'many variables' do
          let(:source) { File.read('spec/fixtures/large_infobox.txt') }
          let(:node) { Parser.inline(source).first }

          it { is_expected.to include('#<Template[Infobox country](common_name: "Argentina"') }
        end
      end

      describe MediaWiki::Page, :vcr do
        let(:node) { Infoboxer.wikipedia.get('Argentina') }

        it {
          is_expected.to match \
            %r{^\#<Page\(title: "Argentina", url: "https://en.wikipedia.org/wiki/Argentina"\): [^<]{,31}\.\.\.>$}
        }
      end
    end
  end
end
