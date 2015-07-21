# encoding: utf-8
module Infoboxer
  describe SectionsNavigation do
    # Document is immutable and is created ~0.3 sec each time.
    # So, fot tens of examples it's wiser to create it only once.
    before(:all){
      @document = Parser.document(File.read('spec/fixtures/argentina.wiki'))
    }
    let(:document){@document}

    describe :intro do
      subject{document.intro}

      it{should be_a(Nodes)}
      its(:count){should == 5}
      it{should == document.paragraphs.first(5)}
    end

    let(:sections){document.sections}

    describe 'basics' do
      it 'should group document in top-level sections' do
        expect(sections.count).to eq(12)
        expect(sections).to all(be_kind_of(Section))
        expect(sections.map(&:heading).map(&:text_)).to eq \
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
      end
    end

    describe Section do
      subject{sections[1]} # History section

      its(:heading){should == Heading.new(Text.new('History'), 2)}

      its(:paragraphs){should be_kind_of(Nodes)}
      its(:'paragraphs.count'){should > 20}

      its(:'sections.count'){should == 8}

      its(:intro){should be_empty}

      it 'should not rewrite nodes parents' do
        expect(subject.children.first.lookup_parents(Document)).not_to be_empty
        expect(subject.children.first.lookup_parents(Section)).to be_empty
      end
    end

    describe 'selected sections' do
      context 'one level' do
        subject{document.sections('History')}

        it{should be_a(Nodes)}
        its(:count){should == 1}
        its(:'first.heading.text_'){should == 'History'}
      end

      context 'several levels' do
        subject{document.sections('History', 'Colonial era')}

        it{should be_a(Nodes)}
        its(:count){should == 1}
        its(:'first.heading.text_'){should == 'Colonial era'}
      end

      context 'two levels: hash' do
        subject{document.sections('History' => 'Colonial era')}

        it{should be_a(Nodes)}
        its(:count){should == 1}
        its(:'first.heading.text_'){should == 'Colonial era'}
      end

      context 'two levels: when second is not existing' do
        subject{document.sections.first.sections}

        it{should be_a(Nodes)}
        it{should be_empty}
      end
    end

    describe :in_sections do
      let(:para){document.lookup(Paragraph, text: /Declassified documents of the Chilean secret police/)}
      subject{para.in_sections}

      its(:count){should == 2}

      it 'should be in order' do
        expect(subject.map(&:heading).map(&:text_)).to eq ['Dirty War', 'History']
      end

      it 'should not rewrite nodes parents' do
        expect(para.lookup_parents(Document)).not_to be_empty
        expect(para.lookup_parents(Section)).to be_empty
      end

      context 'deeply nested nodes' do
        let(:link){document.lookup(ListItem).lookup(Wikilink, text: 'Northwest').first}
        subject{link.in_sections}

        its(:count){should == 2}
        it 'should be in order' do
          expect(subject.map(&:heading).map(&:text_)).to eq ['Regions', 'Geography']
        end
      end

      context 'concrete level' do
      end
      
      context 'if there\'s no' do
      end
    end
  end
end
