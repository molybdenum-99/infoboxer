module Infoboxer
  describe 'other-language Wikipedia', vcr: true do
    let(:client) { MediaWiki.new('https://fr.wikipedia.org/w/api.php') }
    let(:page) { client.get('Argentine') }

    describe 'files' do
      context 'default prefix' do
        # it has prefix File: at the time I'm testing this
        subject { page.lookup(:Image, path: 'Argentine, Billet de 10 centavos édité en 1884.jpg') }

        it { is_expected.not_to be_empty }
      end

      context 'localized prefix' do
        # it has prefix Fichier: at the time I'm testing this
        subject { page.lookup(:Image, path: 'Argentina topo blank.jpg') }

        it { is_expected.not_to be_empty }
      end
    end

    describe 'categories' do
      subject { page.categories }

      it { is_expected.not_to be_empty }
      it 'should include existing category' do
        expect(subject.map(&:name)).to include('Argentine')
      end
    end
  end
end
