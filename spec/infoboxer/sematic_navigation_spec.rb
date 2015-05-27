# encoding: utf-8
module Infoboxer
  describe Document do
    let(:document){
      Parser.parse(File.read('spec/fixtures/argentina.wiki'))
    }

    describe 'simple shortcuts' do

      # FIXME: do we REALLY want to navigate inside templates?..
      describe :wikilinks do
        subject{document.wikilinks}

        its(:count){should > 100}
        its(:'first.link'){should == 'Argentine Constitution'}
        its(:'first.parent'){should be_a(Template)}
      end
      
      describe :external_links do
        subject{document.external_links}

        its(:count){should > 20}
        its(:'first.link'){should == 'http://www.studyspanish.com/lessons/defart2.htm'}
      end
      
      describe :links

      # FIXME: in fact, not an image!!!
      describe :images do
        subject{document.images}

        its(:count){should > 20}
        its(:'first.path'){should == 'Himno Nacional Argentino instrumental.ogg'}
      end
      
      describe :templates do
      end
    end

    describe 'semantic regrouping' do
      describe :sections do
        let(:sections){document.sections}

        it 'should group document in top-level sections' do
          expect(sections.count).to eq(12)
          expect(sections.map(&:heading).map(&:text)
        end
      end
    end
  end
end
