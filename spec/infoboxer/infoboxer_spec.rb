describe Infoboxer do
  describe 'common MediaWiki shortcuts', :vcr do
    context 'Wikipedia' do
      describe 'default' do
        subject { described_class.wikipedia }

        it { is_expected.to be_a(Infoboxer::MediaWiki) }
        its(:'api_base_url.to_s') { is_expected.to eq 'https://en.wikipedia.org/w/api.php' }
      end

      describe 'caching' do
        it 'constructs object only once' do
          w1 = described_class.wikipedia
          w2 = described_class.wikipedia
          expect(w1.object_id).to eq w2.object_id
        end
      end

      describe 'language' do
        subject { described_class.wikipedia('fr') }

        its(:'api_base_url.to_s') { is_expected.to eq 'https://fr.wikipedia.org/w/api.php' }
      end

      describe 'shortcut' do
        subject { described_class.wp('fr') }

        its(:'api_base_url.to_s') { is_expected.to eq 'https://fr.wikipedia.org/w/api.php' }
      end
    end

    context 'Wikia' do
      describe 'simple' do
        subject { described_class.wikia('tardis') }

        it { is_expected.to be_a(Infoboxer::MediaWiki) }
        its(:'api_base_url.to_s') { is_expected.to eq 'http://tardis.wikia.com/api.php' }
      end

      describe 'subdomain' do
        subject { described_class.wikia('ru.tardis') }

        it { is_expected.to be_a(Infoboxer::MediaWiki) }
        its(:'api_base_url.to_s') { is_expected.to eq 'http://ru.tardis.wikia.com/api.php' }
      end

      describe 'language' do
        subject { described_class.wikia('tardis', 'ru') }

        it { is_expected.to be_a(Infoboxer::MediaWiki) }
        its(:'api_base_url.to_s') { is_expected.to eq 'http://ru.tardis.wikia.com/api.php' }
      end
    end
  end
end
