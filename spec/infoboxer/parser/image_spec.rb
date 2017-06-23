# encoding: utf-8
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

      it { should be_a(Tree::Image) }
      its(:path) { should == 'SantaCruz-CuevaManos-P2210651b.jpg' }
    end

    context 'when complex' do
      # real example from http://en.wikipedia.org/wiki/Argentina
      # I love you, Wikipedia!!!!
      let(:source) {
        %q{[[File:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px|The [[Cueva de las Manos|Cave of the Hands]] in [[Santa Cruz province, Argentina|Santa Cruz province]], with indigenous artwork dating from 13,000–9,000 years ago|alt=Stencilled hands on the cave's wall]]}
      }

      it { should be_a(Tree::Image) }
      its(:path) { should == 'SantaCruz-CuevaManos-P2210651b.jpg' }
      its(:type) { should == 'thumb' }
      its(:width) { should == 200 }
      its(:alt) { should == "Stencilled hands on the cave's wall" }

      describe 'caption' do
        subject { nodes.first.caption }

        it { should be_a(Tree::ImageCaption) }
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
        %Q{[[Fichier:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px]]}
      }
      let(:traits) {
        # FIXME: works well in real life, but too complex for test
        MediaWiki::Traits.new({namespaces: [{'canonical' => 'File', '*' => 'Fichier'}]})
      }
      let(:ctx) { Parser::Context.new(source, traits) }

      it { should be_an(Tree::Image) }
      its(:path) { should == 'SantaCruz-CuevaManos-P2210651b.jpg' }

      context 'should parse File: prefix' do
        let(:source) { %Q{[[File:SantaCruz-CuevaManos-P2210651b.jpg|thumb|200px]]} }
        it { should be_an(Tree::Image) }
      end
    end

    context 'multiline' do
      let(:source) {
        "[[File:Diplomatic missions of Argentina.png|thumb|250px|Argentine diplomatic missions:\n"\
        "<div style=\"font-size:90%;\">\n"\
        "{{legend4|#22b14c|Argentina}}\n"\
        "{{legend4|#2f3699|Nations hosting a resident diplomatic mission}}\n"\
        "{{legend4|#b9b9b9|Nations without a resident diplomatic mission}}\n"\
        "</div>]]"
      }

      it { should be_a(Tree::Image) }
      its(:path) { should == 'Diplomatic missions of Argentina.png' }
      its(:width) { should == 250 }
      it 'should have a caption ' do
        expect(subject.caption.children.map(&:class)).to eq \
          [Tree::Text, Tree::Paragraph]
      end
    end
  end
end
