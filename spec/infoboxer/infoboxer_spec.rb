# encoding: utf-8
describe Infoboxer do
  describe 'common MediaWiki shortcuts' do
    context 'Wikipedia' do
      describe 'default' do
        subject{Infoboxer.wikipedia}

        it{should be_a(Infoboxer::MediaWiki)}
        its(:'api_base_url.to_s'){should == 'http://en.wikipedia.org/w/api.php'}
      end

      describe 'language' do
        subject{Infoboxer.wikipedia('fr')}

        its(:'api_base_url.to_s'){should == 'http://fr.wikipedia.org/w/api.php'}
      end

      describe 'shortcut' do
        subject{Infoboxer.wp('fr')}

        its(:'api_base_url.to_s'){should == 'http://fr.wikipedia.org/w/api.php'}
      end
    end

    context 'Wikia' do
      describe 'simple' do
        subject{Infoboxer.wikia('tardis')}

        it{should be_a(Infoboxer::MediaWiki)}
        its(:'api_base_url.to_s'){should == 'http://tardis.wikia.com/api.php'}
      end

      describe 'subdomain' do
        subject{Infoboxer.wikia('ru.tardis')}

        it{should be_a(Infoboxer::MediaWiki)}
        its(:'api_base_url.to_s'){should == 'http://ru.tardis.wikia.com/api.php'}
      end

      describe 'language' do
        subject{Infoboxer.wikia('tardis', 'ru')}

        it{should be_a(Infoboxer::MediaWiki)}
        its(:'api_base_url.to_s'){should == 'http://ru.tardis.wikia.com/api.php'}
      end
    end
  end
end
