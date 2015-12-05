# encoding: utf-8
module Infoboxer
  describe MediaWiki do
    let(:client){MediaWiki.new('https://en.wikipedia.org/w/api.php')}
    
    describe :raw do
      context 'when single page', :vcr do
        subject{client.raw('Argentina').first}

        it{should be_kind_of(MediaWiktory::Page)}
        its(:title){should == 'Argentina'}
        its(:content){should include("'''Argentina'''")}
        its(:fullurl){should == 'https://en.wikipedia.org/wiki/Argentina'}
      end

      context 'when several pages', :vcr do
        subject{client.raw('Argentina', 'Ukraine')}

        it{should be_kind_of(Array)}
        its(:count){should == 2}
        it 'should extract all pages' do
          expect(subject.map(&:title)).to eq %w[Argentina Ukraine]
        end
      end

      context 'when non-existing page', :vcr do
        subject{client.raw('it is non-existing definitely').first}
        its(:title){should == 'It is non-existing definitely'}
        it{should be_missing}
      end

      context 'when redirect page', :vcr do
        subject{client.raw('Einstein').first}

        its(:title){should == 'Albert Einstein'}
        its(:content){should_not include('#REDIRECT')}
        its(:fullurl){should == 'https://en.wikipedia.org/wiki/Albert_Einstein'}
      end

      context 'user-agent', :vcr do
        context 'default' do
          before{client.raw('Argentina')}
          subject{WebMock.last_request}
          its(:headers){should include('User-Agent' => MediaWiki::UA)}
        end

        context 'globally set' do
          before{
            Infoboxer.user_agent = 'My Cool UA'
            client.raw('Argentina')
          }
          subject{WebMock.last_request}
          its(:headers){should include('User-Agent' => 'My Cool UA')}
        end

        context 'locally set' do
          before{
            Infoboxer.user_agent = 'My Cool UA'
            client_with_ua = MediaWiki.new(
              'https://en.wikipedia.org/w/api.php',
              user_agent: 'Something else')
            client_with_ua.raw('Argentina')
          }
          subject{WebMock.last_request}
          its(:headers){should include('User-Agent' => 'Something else')}
        end
      end
    end

    describe :traits, :vcr do
      subject(:traits){client.traits}
      
      context 'static part - guess by domain' do
        subject{traits.templates.find('&')}
        it{should < Templates::Literal}
      end

      context 'dynamic part - taken from API' do
        let(:client){MediaWiki.new('https://fr.wikipedia.org/w/api.php')}
        subject{client.traits}
        its(:file_namespace){should == ['File', 'Fichier', 'Image']}
        its(:category_namespace){should == ['Category', 'Catégorie']}
      end

      context 'custom part - set on creation' do
      end
    end

    describe :get, :vcr do
      context 'when single page', :vcr do
        subject{client.get('Argentina')}

        it{should be_a(MediaWiki::Page)}
        its(:title){should == 'Argentina'}
        its(:url){should == 'https://en.wikipedia.org/wiki/Argentina'}
        its(:source){should be_a(MediaWiktory::Page)}
      end

      context 'when several pages', :vcr do
        subject{client.get('Argentina', 'Ukraine')}

        it{should all(be_a(MediaWiki::Page))}
      end

      context 'when signle non-existing page' do
        subject{client.get('Why I am still trying this kind of stuff, huh?')}

        it{should be_nil}
      end

      context 'when several pages, including non-existent' do
        subject{client.get('Argentina', 'Ukraine', 'WTF I just read? Make me unsee it')}

        its(:count){should == 2}
      end
    end
  end
end
