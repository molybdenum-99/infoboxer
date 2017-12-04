module Infoboxer
  describe 'Integration of MediaWiki::Traits into data' do
    before do
      MediaWiki::Traits.templates.clear
      MediaWiki::Traits.domains.clear
    end

    describe 'template expansion on-the-fly' do
      let(:klass) {
        Class.new(MediaWiki::Traits) do
          templates do
            show 'join'

            replace('!' => '|', ',' => '·')
          end
        end
      }
      let(:traits) { klass.new }
      let(:nodes) {
        Parser.inline(source, traits)
      }

      context 'when simple nested templates' do
        let(:source) {
          "before {{join|{{!}} text|and ''italics''}} after"
        }

        subject { nodes }

        its(:text) { is_expected.to eq 'before | text and italics after' }
      end

      context 'when multiline templates' do
        let(:source) {
          "{{unknown|{{!}}\n\ntext\n\nfoo {{,}}}}r"
        }

        subject { nodes.first.variables.first.children }

        it {
          is_expected.to eq [
            traits.templates.find('!').new('!'),
            Tree::Paragraph.new(Tree::Text.new('text')),
            Tree::Paragraph.new([Tree::Text.new('foo '), traits.templates.find(',').new(',')]),
          ]
        }
        its(:text) { is_expected.to eq "|text\n\nfoo ·\n\n" }
      end

      context 'when templates in image caption' do
        let(:source) {
          '[[File:image.png|This {{!}} that]]'
        }

        subject {
          nodes.first.caption
        }

        its(:text) { is_expected.to eq 'This | that' }
      end

      context 'when templates in tables' do
        let(:source) {
          "{|\n|+Its in {{!}} caption!\n|}"
        }
        let(:table) { Parser.paragraphs(source, traits).first }

        subject { table.lookup(:TableCaption).first }

        its(:text) { is_expected.to eq 'Its in | caption!' }
      end
    end

    xdescribe 'context selection by client' do
      context 'when defined' do
        let!(:klass) {
          Class.new(MediaWiki::Traits) do
            domain 'en.wikipedia.org'

            templates_text(
              '!' => '|',
              ',' => '·'
            )
            template('join') { |t| Nodes[*t.variables.values] }
          end
        }
        let(:client) { MediaWiki.new('http://en.wikipedia.org/w/api.php') }

        subject { client }

        its(:context) { is_expected.to be_a(klass) }
      end

      context 'when not defined' do
      end
    end
  end
end
