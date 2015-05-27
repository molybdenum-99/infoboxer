# encoding: utf-8
module Infoboxer
  describe Document do
    let(:document){
      Parser.parse(File.read('spec/fixtures/argentina.wiki'))
    }

    describe 'simple shortcuts' do
      describe :wikilinks do
        context 'by default' do
          subject{document.wikilinks}

          its(:count){should > 100}
          its(:'first.link'){should == 'federal republic'}
          its(:'first.parent'){should be_a(Paragraph)}
          it 'should have no namespaced link' do
            expect(subject.map(&:link)).to all(match(/^[^:]+$/))
          end
        end
      end
      
      describe :external_links do
        subject{document.external_links}

        its(:count){should > 20}
        its(:'first.link'){should == 'http://www.studyspanish.com/lessons/defart2.htm'}
      end
      
      describe :links

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
    end

    #describe 'semantic regrouping' do
      #describe :sections do
        #let(:sections){document.sections}

        #it 'should group document in top-level sections' do
          #expect(sections.count).to eq(12)
          #expect(sections.map(&:heading).map(&:text))
        #end
      #end
    #end
  end
end
