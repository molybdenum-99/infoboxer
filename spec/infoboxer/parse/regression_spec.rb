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

    end
  end
end
