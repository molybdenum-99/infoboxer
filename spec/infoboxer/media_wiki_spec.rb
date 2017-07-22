# encoding: utf-8

module Infoboxer
  describe MediaWiki, :vcr do
    let(:client) { MediaWiki.new('https://en.wikipedia.org/w/api.php') }

    describe :inspect do
      subject { client }

      its(:inspect) { is_expected.to eq '#<Infoboxer::MediaWiki(en.wikipedia.org)>' }
    end

    describe :raw do
      # TODO: rewrite specs for new, hash-returning implementation
      context 'single page' do
        subject(:page) { client.raw(title).values.first }

        context 'default' do
          let(:title) { 'Argentina' }

          it { is_expected.to be_a Hash }
          its(['title']) { is_expected.to eq 'Argentina' }
          it { expect(subject['revisions'].first['*']).to include("'''Argentina'''") }
          its(['fullurl']) { is_expected.to eq 'https://en.wikipedia.org/wiki/Argentina' }
        end

        context 'non-existent' do
          let(:title) { 'it is non-existing definitely' }

          its(['title']) { is_expected.to eq 'It is non-existing definitely' }
          its(['missing']) { is_expected.to be_truthy }
        end

        context 'redirect' do
          let(:title) { 'Einstein' }

          its(['title']) { is_expected.to eq 'Albert Einstein' }
          it { expect(subject['revisions'].first['*']).not_to include('#REDIRECT') }
          its(['fullurl']) { is_expected.to eq 'https://en.wikipedia.org/wiki/Albert_Einstein' }
        end
      end

      context 'several pages' do
        subject(:pages) { client.raw(*titles).values }

        context 'default' do
          let(:titles) { %w[Argentina Ukraine] }

          it { is_expected.to be_an Array }
          its(:count) { is_expected.to eq 2 }
          its_map(['title']) { is_expected.to eq %w[Argentina Ukraine] }
        end

        context '> 50 pages' do
          let(:titles) { (1920..1975).map(&:to_s) }

          it { is_expected.to be_an Array }
          its(:count) { is_expected.to eq titles.count }
          its_map(['title']) { is_expected.to eq titles }
        end

        context 'no pages' do
          # could emerge on "automatically" created page lists, should work
          let(:titles) { [] }

          it { is_expected.to be_an(Array).and be_empty }
        end

        xcontext 'preserve order, even with redirects' do
          let(:titles) { %w[Oster Einstein Bolhrad] }

          its_map(['title']) { is_expected.to eq ['Oster', 'Albert Einstein', 'Bolhrad'] }
        end
      end

      context 'user-agent' do
        subject { WebMock.last_request.headers }

        context 'default' do
          before { client.raw('Argentina') }
          it { is_expected.to include('User-Agent' => MediaWiki::UA) }
        end

        context 'globally set' do
          before {
            Infoboxer.user_agent = 'My Cool UA'
            client.raw('Argentina')
          }
          it { is_expected.to include('User-Agent' => 'My Cool UA') }
        end

        context 'locally set' do
          before {
            Infoboxer.user_agent = 'My Cool UA'
            client_with_ua = MediaWiki.new(
              'https://en.wikipedia.org/w/api.php',
              user_agent: 'Something else'
            )
            client_with_ua.raw('Argentina')
          }
          it { is_expected.to include('User-Agent' => 'Something else') }
        end
      end
    end

    describe :traits do
      subject(:traits) { client.traits }

      context 'static part - guess by domain' do
        subject { traits.templates.find('&') }

        it { is_expected.to be < Templates::Literal }
      end

      context 'dynamic part - taken from API' do
        let(:client) { MediaWiki.new('https://fr.wikipedia.org/w/api.php') }

        context 'before first page fetched' do
          its(:file_namespace) { is_expected.to contain_exactly('File', 'Fichier', 'Image') }
          its(:category_namespace) { is_expected.to contain_exactly('Category', 'Catégorie') }
        end

        context 'after page fetched' do
          before { client.get('Paris') }

          its(:file_namespace) { is_expected.to contain_exactly('File', 'Fichier', 'Image') }
          its(:category_namespace) { is_expected.to contain_exactly('Category', 'Catégorie') }
        end
      end
    end

    describe :get do
      context 'when single page' do
        subject { client.get('Argentina') }

        it { is_expected.to be_a MediaWiki::Page }
        its(:title) { is_expected.to eq 'Argentina' }
        its(:url) { is_expected.to eq 'https://en.wikipedia.org/wiki/Argentina' }
        its(:source) { is_expected.to match hash_including('title' => 'Argentina') }
      end

      context 'when several pages' do
        subject { client.get('Argentina', 'Ukraine') }

        it { is_expected.to all be_a MediaWiki::Page }
      end

      context 'when signle non-existing page' do
        subject { client.get('Why I am still trying this kind of stuff, huh?') }

        it { is_expected.to be_nil }
      end

      context 'when several pages, including non-existent' do
        subject { client.get('Argentina', 'Ukraine', 'WTF I just read? Make me unsee it') }

        its(:count) { is_expected.to eq 2 }
      end

      context 'when invalid title requested' do
        subject { client.get('It%27s not') }

        its_call { is_expected.to raise_error(/contains invalid characters/) }
      end

      describe ':prop' do
        subject { client.get('Argentina', prop: :wbentityusage) }

        its(:source) { is_expected.to have_key('wbentityusage') }
      end
    end

    describe :get_h do
      subject { client.get_h(*titles) }

      context 'when several pages, including non-existent' do
        let(:titles) { ['Argentina', 'Ukraine', 'WTF I just read? Make me unsee it'] }

        it { is_expected.to be_a Hash }
        its(:keys) { are_expected.to eq ['Argentina', 'Ukraine', 'WTF I just read? Make me unsee it'] }
        its(['WTF I just read? Make me unsee it']) { is_expected.to be_nil }
      end

      context 'when several pages, including redirected to same' do
        let(:titles) { ['Kharkiv', 'Kharkov', 'Kharkiv, Ukraine'] }

        it { is_expected.to be_a Hash }
        its(:keys) { are_expected.to eq ['Kharkiv', 'Kharkov', 'Kharkiv, Ukraine'] }
        its(:values) { are_expected.to all be_a MediaWiki::Page }
        its(:values) { are_expected.to all have_attributes(title: 'Kharkiv') }

        # TODO: parse all synonyms in one pass
        # its(:'values.uniq.count') { is_expected.to eq 1 }
      end

      context 'with downcase titles' do
        let(:titles) { ['kharkiv'] }

        it { is_expected.to be_a Hash }
        its(:keys) { are_expected.to eq ['kharkiv'] }
        its(:values) { are_expected.to all be_a MediaWiki::Page }
      end
    end

    describe :category do
      subject(:response) { client.category(category) }

      context 'when category exists' do
        let(:category) { 'Category:Ukrainian rock music groups' }

        it { is_expected.to be_a(Tree::Nodes) }
        its(:count) { is_expected.to be > 40 }

        its_map(:title) { is_expected.to include('Dymna Sumish', 'Okean Elzy', 'Vopli Vidopliassova') }
      end

      context 'when category is not' do
        let(:category) { 'Category:krainian rock music groups' }

        it { is_expected.to be_a(Tree::Nodes) }
        it { is_expected.to be_empty }
      end

      describe 'category name transformation' do
        # FIXME: better webmock specs!
        subject { WebMock.last_request }

        before { response }

        context 'when no namespace' do
          let(:category) { 'Ukrainian rock music groups' }

          its(:'uri.query_values') { is_expected.to include('gcmtitle' => 'Category:Ukrainian rock music groups') }
        end

        context 'default namespace' do
          let(:category) { 'Category:Ukrainian rock music groups' }

          its(:'uri.query_values') { is_expected.to include('gcmtitle' => 'Category:Ukrainian rock music groups') }
        end

        context 'localized namespace' do
          let(:client) { MediaWiki.new('https://es.wikipedia.org/w/api.php') }
          let(:category) { 'Categoría:Grupos de rock de Ucrania' }

          its(:'uri.query_values') { is_expected.to include('gcmtitle' => 'Categoría:Grupos de rock de Ucrania') }
        end

        context 'not a namespace' do
          let(:category) { 'Ukrainian: rock music groups' }

          its(:'uri.query_values') { is_expected.to include('gcmtitle' => 'Category:Ukrainian: rock music groups') }
        end
      end
    end

    describe :search do
      subject { client.search(query) }

      context 'when found' do
        let(:query) { 'intitle:"town tramway systems in Chile"' }

        it { is_expected.to be_a(Tree::Nodes) }
        its(:count) { is_expected.to eq 1 }

        its_map(:title) { is_expected.to include('List of town tramway systems in Chile') }
      end

      context 'when not found' do
        let(:query) { 'intitle:"town tramway systems in Vunuatu"' }

        it { is_expected.to be_a(Tree::Nodes).and be_empty }
      end
    end

    describe :prefixsearch do
      subject { client.prefixsearch(prefix) }

      context 'when found' do
        let(:prefix) { 'Ukrainian hr' }

        it { is_expected.to be_a(Tree::Nodes) }
        its(:count) { is_expected.to be > 1 }

        its_map(:title) { is_expected.to include('Ukrainian hryvnia') }
      end

      context 'when not found' do
        let(:prefix) { 'Ukrainian foooo' }

        it { is_expected.to be_a(Tree::Nodes).and be_empty }
      end
    end
  end
end
