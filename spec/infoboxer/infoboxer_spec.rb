# encoding: utf-8
describe Infoboxer do
  describe 'common MediaWiki shortcuts', :vcr do
    context 'Wikipedia' do
      describe 'default' do
        subject{Infoboxer.wikipedia}

        it{should be_a(Infoboxer::MediaWiki)}
        its(:'api_base_url.to_s'){should == 'https://en.wikipedia.org/w/api.php'}
      end

      describe 'caching' do
        it 'constructs object only once' do
          w1 = Infoboxer.wikipedia
          w2 = Infoboxer.wikipedia
          expect(w1.object_id).to eq w2.object_id
        end
      end

      describe 'language' do
        subject{Infoboxer.wikipedia('fr')}

        its(:'api_base_url.to_s'){should == 'https://fr.wikipedia.org/w/api.php'}
      end

      describe 'shortcut' do
        subject{Infoboxer.wp('fr')}

        its(:'api_base_url.to_s'){should == 'https://fr.wikipedia.org/w/api.php'}
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

    context 'Configuration' do
      describe '.configuration' do
        subject { Infoboxer.configuration }

        it{should be_a(Infoboxer::Configuration)}
      end
    end
  end
end
