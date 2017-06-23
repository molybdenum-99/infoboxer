# encoding: utf-8

module Infoboxer
  describe Navigation::Shortcuts do
    # Document is immutable and is created ~0.3 sec each time.
    # So, fot tens of examples it's wiser to create it only once.
    before(:all) {
      @document = Parser.document(File.read('spec/fixtures/argentina.wiki'))
    }
    let(:document) { @document }

    describe :wikilinks do
      context 'by default' do
        subject { document.wikilinks }

        its(:count) { is_expected.to be > 100 }
        its(:'first.link') { is_expected.to eq 'Argentine Constitution' }
        its(:'first.parent') { is_expected.to be_a(Tree::Var) }
        it 'should have no namespaced link' do
          expect(subject.map(&:link)).not_to include(match(/:$/))
        end
      end

      context 'by namespace' do
        subject { document.wikilinks('Category') }

        its(:'first.link') { is_expected.to eq 'Category:Argentina' }
        it 'should have all links namespaced' do
          expect(subject.map(&:link)).to all(match(/^Category:/))
        end
      end

      context 'all namespaces' do
        subject { document.wikilinks(nil) }

        it 'should have all kinds of links' do
          expect(subject.map(&:link)).to include(match(/^Category:/))
          expect(subject.map(&:link)).to include(match(/^[^:]+$/))
        end
      end
    end

    describe :external_links do
      subject { document.external_links }

      its(:count) { is_expected.to be > 20 }
      its(:'first.link') { is_expected.to eq 'http://www.studyspanish.com/lessons/defart2.htm' }
    end

    describe :images do
      subject { document.images }

      its(:count) { is_expected.to be > 20 }
      its_map(:path) { is_expected.to include 'SantaCruz-CuevaManos-P2210651b.jpg' }
    end

    describe :templates do
      subject { document.templates }

      its(:count) { is_expected.to be > 10 }
      its(:'first.name') { is_expected.to eq 'other uses' }
    end

    describe :tables do
      subject { document.tables }

      its(:count) { is_expected.to be > 0 }
      its(:first) { is_expected.to be_a(Tree::Table) }
    end

    # FIXME: With new templates policy, #paragraphs shortcut seems useless
    xdescribe :paragraphs do
      subject { document.paragraphs }
      its(:count) { is_expected.to be > 100 }
      it 'should be only paragraph-level nodes' do
        expect(subject.map(&:class).uniq).to \
          contain_exactly(Tree::Paragraph, Tree::ListItem, Tree::Heading, Tree::DTerm, Tree::DDefinition)
      end
    end

    describe :headings do
      subject { document.headings }
      its(:count) { is_expected.to eq 46 }

      it 'should select by level' do
        expect(document.headings(2).count).to eq 12
        expect(document.headings(3).count).to eq 34
        expect(document.headings(4).count).to eq 0
      end
    end
  end
end
