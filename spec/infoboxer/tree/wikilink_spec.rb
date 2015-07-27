# encoding: utf-8
module Infoboxer
  module Tree
    describe Wikilink do
      describe 'plain vanilla' do
        subject{Wikilink.new('Test')}
        its(:name){should == 'Test'}
        its(:namespace){should == ''}
        its(:anchor){should == ''}
        its(:topic){should == 'Test'}
        its(:refinement){should == ''}
      end
      
      context :namespace do
        subject{Wikilink.new('Category:Test')}
        its(:name){should == 'Test'}
        its(:namespace){should == 'Category'}

        # TODO: check how Wikipedia thinks about it, internally!
        context 'when deeper' do
        end
      end

      context :anchor do
        subject{Wikilink.new('Test#Yourself')}
        its(:name){should == 'Test'}
        its(:anchor){should == 'Yourself'}
      end

      context :topic do
        context ',' do
          subject{Wikilink.new('Phoenix, Arizona')}
          its(:topic){should == 'Phoenix'}
          its(:refinement){should == 'Arizona'}

          context 'when several commas' do
            subject{Wikilink.new('Phoenix, Arizona, USA')}
            its(:topic){should == 'Phoenix'}
            its(:refinement){should == 'Arizona, USA'}
          end
        end

        context '()' do
          subject{Wikilink.new('Pipe (computing)')}
          its(:topic){should == 'Pipe'}
          its(:refinement){should == 'computing'}
        end

        context ', ()' do
          subject{Wikilink.new('Phoenix, Arizona (USA)')}
          its(:topic){should == 'Phoenix, Arizona'}
          its(:refinement){should == 'USA'} 
        end
      end

      describe 'everything at once!' do
        subject{Wikilink.new('Talk:Me, myself and Irene (film, bad)#Reception')}
        its(:name){should == 'Me, myself and Irene (film, bad)'}
        its(:namespace){should == 'Talk'}
        its(:anchor){should == 'Reception'}
        its(:topic){should == 'Me, myself and Irene'}
        its(:refinement){should == 'film, bad'}
      end

      describe 'pipe trick' do
        subject{Wikilink.new('Phoenix, Arizona', Text.new(''))}
        its(:children){should == [Text.new('Phoenix')]}
      end
    end
  end
end
