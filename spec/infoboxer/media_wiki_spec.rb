# encoding: utf-8
module Infoboxer
  describe MediaWiki do
    let(:client){MediaWiki.new('http://en.wikipedia.org/w/api.php')}
    
    describe :raw do
      context 'when single page', :vcr do
        subject{client.raw('Argentina').first}

        it{should be_kind_of(Hash)}
        its([:title]){should == 'Argentina'}
        its([:content]){should include("'''Argentina'''")}
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
      end
    end

    describe :get, :vcr do
      subject{client.get('Argentina')}

      it{should be_a(Page)}
      its(:title){should == 'Argentina'}
      its(:url){should == 'http://en.wikipedia.org/wiki/Argentina'}
    end
  end
end
