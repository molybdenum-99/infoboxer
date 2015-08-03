# encoding: utf-8
module Infoboxer
  describe Templates::Set do
    context 'definition' do
      let(:set){
        described_class.new do
          template 'Largest cities' do
            def city_names
              fetch(/city_\d+/).map(&:text)
            end
          end

          template 'Infobox', match: /^Infobox/i do
            def infobox?
              true
            end
          end

          template 'Infobox cheese', base: 'Infobox'

          template 'convert' do
            def children
              fetch('1', '3', '5')
            end

            def text
              fetch('1').text
            end
          end

          replace '!' => '|',
                  ',' => '·'
        end
      }

      context 'standalone template' do
        subject{set.find('Largest cities')}
        it{should be_a(Class)}
        it{should < Templates::Base}
        its(:inspect){should == 'Infoboxer::Templates::Template[Largest cities]'}
        its(:instance_methods){should include(:city_names)}

        it 'should be case-insensitive' do
          expect(set.find('largest cities')).to eq set.find('Largest cities')
        end
      end

      context 'explicit match option' do
        subject{set.find('Infobox country')}
        it{should be_a(Class)}
        it{should < Tree::Template}
        its(:inspect){should == 'Infoboxer::Templates::Template[Infobox]'}
      end

      context 'explicit base option' do
        subject{set.find('Infobox cheese')}
        it{should be_a(Class)}
        it{should < set.find('Infobox')}
        its(:inspect){should == 'Infoboxer::Templates::Template[Infobox cheese]'}
        its(:instance_methods){should include(:infobox?)}
      end

      context 'defaults' do
        subject{set.find('undefined')}
        it{should be_a(Class)}
        it{should == Templates::Base}
      end

      context 'helpers' do
        subject{set.find('!').new('!')}
        it{should be_kind_of(Templates::Replace)}
        its(:text){should == '|'}
      end

      context 'redefinition' do
      end
    end
  end
end
