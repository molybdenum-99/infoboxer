# encoding: utf-8
module Infoboxer
  describe MediaWiki do
    let(:client){MediaWiki.new('https://en.wikipedia.org/w/api.php')}
    
    describe :raw do
      context 'when single page', :vcr do
        subject{client.raw('Argentina').first}

        it{should be_kind_of(Hash)}
        its([:title]){should == 'Argentina'}
        its([:content]){should include("'''Argentina'''")}
        its([:url]){should == 'https://en.wikipedia.org/wiki/Argentina'}
      end

      context 'when several pages', :vcr do
        subject{client.raw('Argentina', 'Ukraine')}

        it{should be_kind_of(Array)}
        its(:count){should == 2}
        it 'should extract all pages' do
          expect(subject.map{|r| r[:title]}).to eq %w[Argentina Ukraine]
        end
      end

      context 'when non-existing page', :vcr do
        it 'should throw' do
          expect{client.raw('it is non-existing definitely')}.to \
            raise_error(MediaWiki::PageNotFound)
        end
      end

      context 'when redirect page', :vcr do
        subject{client.raw('Einstein').first}
        its([:title]){should == 'Albert Einstein'}
        its([:content]){should_not include('#REDIRECT')}
        its([:url]){should == 'https://en.wikipedia.org/wiki/Albert_Einstein'}
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

    describe :get, :vcr do
      context 'when single page', :vcr do
        subject{client.get('Argentina')}

        it{should be_a(Page)}
        its(:title){should == 'Argentina'}
        its(:url){should == 'https://en.wikipedia.org/wiki/Argentina'}
      end

      context 'when several pages', :vcr do
        subject{client.get('Argentina', 'Ukraine')}

        it{should all(be_a(Page))}
      end
    end
  end
end
