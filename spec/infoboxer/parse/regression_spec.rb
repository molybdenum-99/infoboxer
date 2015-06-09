# encoding: utf-8
module Infoboxer
  describe Parse, 'complicated and erroneous examples' do
    context 'inline node' do
      subject{Parse.inline(source).first}

      # from http://en.wikipedia.org/wiki/Canada
      describe 'Canada - image with templates' do
        let(:source){
          %q{[[File:Bilinguisme au Canada-fr.svg|200px|thumb|Approximately 98% of Canadians can speak English and/or French.<ref name="Highlights"/>'''<small>{{Legend|#FFE400|English – 56.9%}}{{Legend|#D8A820|English and French (Bilingual) – 16.1% }}{{Legend|#B07400|French – 21.3%}}{{Legend|#F5F5DC|Sparsely populated area ( '''&lt;''' 0.4 persons per km<sup>2</sup>)}}</small>''']]}
        }
        it{should be_an(Image)}
      end

      describe 'Ukraine - complex ref' do
        let(:source){
          %q{<ref>one<br></ref><ref>other</ref>}
        }
        it{should be_a(Ref)}
        its(:text){should == 'one'}
      end

      describe 'USA - template with HTML inside' do
        let(:source){
          %q{{{triple image|right|Capitol Building Full View.jpg|202|WhiteHouseSouthFacade.JPG|120|USSupremeCourtWestFacade.JPG|125|<center>The [[United States Capitol]],<br /> where [[United States Congress|Congress]] meets:<br />the [[United States Senate|Senate]], left; the [[United States House of Representatives|House]], right|<center>The [[White House]], home of the [[President of the United States|U.S. President]]|<center>[[United States Supreme Court Building|Supreme Court Building]], where the [[Supreme Court of the United States|nation's highest court]] sits</center>}}}
        }
        it{should be_a(Template)}
        its(:'variables.count'){should == 8}
      end
    end
  end
end
