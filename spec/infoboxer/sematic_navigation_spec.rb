# encoding: utf-8
module Infoboxer
  describe Document do
    # Document is immutable and is created ~0.3 sec each time.
    # So, fot tens of examples it's wiser to create it only once.
    before(:all){
      @document = Parser.document(File.read('spec/fixtures/argentina.wiki'))
    }
    let(:document){ @document }

    describe 'simple shortcuts' do
      describe :wikilinks do
        context 'by default' do
          subject{document.wikilinks}

          its(:count){should > 100}
          its(:'first.link'){should == 'federal republic'}
          its(:'first.parent'){should be_a(Paragraph)}
          it 'should have no namespaced link' do
            expect(subject.map(&:link)).not_to include(match(/:$/))
          end
        end

        context 'by namespace' do
          subject{document.wikilinks('Category')}

          its(:'first.link'){should == 'Category:Argentina'}
          it 'should have all links namespaced' do
            expect(subject.map(&:link)).to all(match(/^Category:/))
          end
        end

        context 'all namespaces' do
          subject{document.wikilinks(nil)}

          it 'should have all kinds of links' do
            expect(subject.map(&:link)).to include(match(/^Category:/))
            expect(subject.map(&:link)).to include(match(/^[^:]+$/))
          end
        end
      end
      
      describe :external_links do
        subject{document.external_links}

        its(:count){should > 20}
        its(:'first.link'){should == 'http://www.studyspanish.com/lessons/defart2.htm'}
      end
      
      describe :images do
        subject{document.images}

        its(:count){should > 20}
        its(:'first.path'){should == 'SantaCruz-CuevaManos-P2210651b.jpg'}
      end
      
      describe :templates do
        subject{document.templates}

        its(:count){should > 10}
        its(:'first.name'){should == 'other uses'}
      end

      describe :tables do
        subject{document.tables}

        its(:count){should > 0}
        its(:first){should be_a(Table)}
      end

      describe :paragraphs do
        subject{document.paragraphs}
        its(:count){should > 100}
        it 'should be only paragraph-level nodes' do
          expect(subject.map(&:class).uniq).to \
            contain_exactly(Paragraph, ListItem, Heading, DTerm, DDefinition)
        end
      end

      describe :headings do
        subject{document.headings}
        its(:count){should == 46}

        it 'should select by level' do
          expect(document.headings(2).count).to eq 12
          expect(document.headings(3).count).to eq 34
          expect(document.headings(4).count).to eq 0
        end
      end
    end

    describe 'semantic regrouping' do
      describe :intro do
        
        subject{document.intro}

        it{should be_a(Nodes)}
        its(:count){should == 5}
        it{should == document.paragraphs.first(5)}
      end
      
      describe :sections do
        let(:sections){document.sections}

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

        describe Section do
          subject{sections[1]} # History section

          its(:heading){should == Heading.new(Text.new('History'), 2)}

          its(:paragraphs){should be_kind_of(Nodes)}
          its(:'paragraphs.count'){should > 20}

          its(:'sections.count'){should == 8}

          its(:intro){should be_empty}
        end
      end

      describe :sections, 'selected sections' do
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
    end
  end
end
