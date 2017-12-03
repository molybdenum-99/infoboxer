module Infoboxer
  describe Navigation::Sections do
    # Document is immutable and is created ~0.3 sec each time.
    # So, fot tens of examples it's wiser to create it only once.
    before(:all) {
      @document = Parser.document(File.read('spec/fixtures/argentina.wiki'))
    }
    let(:document) { @document }

    describe :intro do
      subject { document.intro }

      it { is_expected.to be_a(Tree::Nodes) }
      its(:count) { is_expected.to eq 7 }
      it { is_expected.to eq document.children.grep(Tree::BaseParagraph).first(7) }
    end

    describe :sections do
      subject(:sections) { document.sections }

      describe 'basics' do
        its(:count) { is_expected.to eq 12 }
        it { is_expected.to all(be_kind_of(Navigation::Sections::Section)) }
        its_map(:'heading.text_') {
          are_expected.to eq \
            [
              'Name and etymology',
              'History',
              'Geography',
              'Politics',
              'Economy',
              'Demographics',
              'Culture',
              'See also',
              'Notes',
              'References',
              'Bibliography',
              'External links'
            ]
        }
      end

      describe '#lookup_children' do
        subject { document.lookup_children(:Section).first }

        it { is_expected.to eq sections[0] }
      end

      describe Navigation::Sections::Section do
        subject { sections[1] } # History section

        its(:heading) { is_expected.to eq Tree::Heading.new(Tree::Text.new('History'), 2) }
        its(:inspect) { is_expected.to eq '#<Section(level: 2, heading: "History"): 39 nodes>' }

        its(:paragraphs) { is_expected.to be_kind_of(Tree::Nodes) }
        its(:'paragraphs.count') { is_expected.to be > 20 }

        its(:'sections.count') { is_expected.to eq 8 }

        its(:'intro.count') { is_expected.to eq 1 }

        it 'should not rewrite nodes parents' do
          expect(subject.children.first.lookup_parents(Tree::Document)).not_to be_empty
          expect(subject.children.first.lookup_parents(Navigation::Sections::Section)).to be_empty
        end
      end

      describe 'selected sections' do
        context 'one level' do
          subject { document.sections('History') }

          it { is_expected.to be_a(Tree::Nodes) }
          its(:count) { is_expected.to eq 1 }
          its(:'first.heading.text_') { is_expected.to eq 'History' }
        end

        context 'several levels' do
          subject { document.sections('History', 'Colonial era') }

          it { is_expected.to be_a(Tree::Nodes) }
          its(:count) { is_expected.to eq 1 }
          its(:'first.heading.text_') { is_expected.to eq 'Colonial era' }
        end

        context 'two levels: hash' do
          subject { document.sections('History' => 'Colonial era') }

          it { is_expected.to be_a(Tree::Nodes) }
          its(:count) { is_expected.to eq 1 }
          its(:'first.heading.text_') { is_expected.to eq 'Colonial era' }
        end

        context 'two levels: when second is not existing' do
          subject { document.sections.first.sections }

          it { is_expected.to be_a(Tree::Nodes) }
          it { is_expected.to be_empty }
        end
      end
    end

    describe :in_sections do
      let(:para) { document.lookup(:Paragraph, text: /Declassified documents of the Chilean secret police/) }

      subject { para.in_sections }

      its(:count) { is_expected.to eq 2 }

      its_map(:'heading.text_') { is_expected.to eq ['Dirty War', 'History'] }

      it 'should not rewrite nodes parents' do
        expect(para.lookup_parents(:Document)).not_to be_empty
        expect(para.lookup_parents(:Section)).to be_empty
      end

      context 'deeply nested nodes' do
        let(:link) { document.lookup(:ListItem).lookup(:Wikilink, text: 'Northwest').first }

        subject { link.in_sections }

        its(:count) { is_expected.to eq 2 }
        its_map(:'heading.text_') { is_expected.to eq %w[Regions Geography] }
      end

      context 'concrete level' do
      end

      context "if there's no" do
      end
    end
  end
end
