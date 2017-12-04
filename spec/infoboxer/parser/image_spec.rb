require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'images and media' do
    let(:ctx) { Parser::Context.new(source) }
    let(:parser) { Parser.new(ctx) }

    let(:nodes) { parser.inline }

    subject { nodes.first }

    context 'when simplest' do
      let(:source) {
        %q{[[File:SantaCruz-CuevaManos-P2210651b.jpg]]}
      }

      it { is_expected.to be_a(Tree::Image) }
      its(:path) { is_expected.to eq 'SantaCruz-CuevaManos-P2210651b.jpg' }
    end

    context 'when complex' do
      # real example from http://en.wikipedia.org/wiki/Argentina
      # I love you, Wikipedia!!!!
      let(:source) {
        %q{[[File:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px|The [[Cueva de las Manos|Cave of the Hands]] in [[Santa Cruz province, Argentina|Santa Cruz province]], with indigenous artwork dating from 13,000–9,000 years ago|alt=Stencilled hands on the cave's wall]]}
      }

      it { is_expected.to be_a(Tree::Image) }
      its(:path) { is_expected.to eq 'SantaCruz-CuevaManos-P2210651b.jpg' }
      its(:type) { is_expected.to eq 'thumb' }
      its(:width) { is_expected.to eq 200 }
      its(:alt) { is_expected.to eq "Stencilled hands on the cave's wall" }

      describe 'caption' do
        subject { nodes.first.caption }

        it { is_expected.to be_a(Tree::ImageCaption) }
        it 'should preserve all data' do
          expect(subject.children.map(&:class)).to eq \
            [Tree::Text, Tree::Wikilink, Tree::Text, Tree::Wikilink, Tree::Text]

          expect(subject.children.map(&:text)).to eq [
            'The ',
            'Cave of the Hands',
            ' in ',
            'Santa Cruz province',
            ', with indigenous artwork dating from 13,000–9,000 years ago'
          ]
          expect(subject.text).to eq 'The Cave of the Hands in Santa Cruz province, with indigenous artwork dating from 13,000–9,000 years ago'
        end
      end
    end

    context 'with non-default site traits provided' do
      let(:source) {
        %{[[Fichier:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px]]}
      }
      let(:ctx) { Parser::Context.new(source) }

      before {
        allow_any_instance_of(MediaWiki::Traits).to receive(:file_namespace).and_return(%w[File Fichier]) # rubocop:disable RSpec/AnyInstance
      }

      it { is_expected.to be_an(Tree::Image) }
      its(:path) { is_expected.to eq 'SantaCruz-CuevaManos-P2210651b.jpg' }

      context 'should parse File: prefix' do
        let(:source) { %{[[File:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px]]} }

        it { is_expected.to be_an(Tree::Image) }
      end
    end

    context 'multiline' do
      let(:source) {
        "[[File:Diplomatic missions of Argentina.png|thumb|250px|Argentine diplomatic missions:\n"\
        "<div style=\"font-size:90%;\">\n"\
        "{{legend4|#22b14c|Argentina}}\n"\
        "{{legend4|#2f3699|Nations hosting a resident diplomatic mission}}\n"\
        "{{legend4|#b9b9b9|Nations without a resident diplomatic mission}}\n"\
        '</div>]]'
      }

      it { is_expected.to be_a(Tree::Image) }
      its(:path) { is_expected.to eq 'Diplomatic missions of Argentina.png' }
      its(:width) { is_expected.to eq 250 }
      it 'should have a caption ' do
        expect(subject.caption.children.map(&:class)).to eq \
          [Tree::Text, Tree::Paragraph]
      end
    end
  end
end
