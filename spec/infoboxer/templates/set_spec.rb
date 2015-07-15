# encoding: utf-8
module Infoboxer
  module Aux
  end
  
  describe TemplateSet do
    before do
      Aux.constants.each do |c|
        Aux.send(:remove_const, c)
      end
    end
    
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

          inflow_template 'convert' do
            def children
              fetch('1', '3', '5')
            end

            def text
              fetch('1').text
            end
          end

          text '!' => '|',
            ',' => '·'
        end
      }

      context 'standalone template' do
        subject{set.find('Largest cities')}
        it{should be_a(Class)}
        it{should < Template}
        its(:inspect){should == '#<Template[Largest cities]>'}
        its(:instance_methods){should include(:city_names)}

        it 'should be case-insensitive' do
          expect(set.find('largest cities')).to eq set.find('Largest cities')
        end
      end

      context 'explicit match option' do
        subject{set.find('Infobox country')}
        it{should be_a(Class)}
        it{should < Template}
        its(:inspect){should == '#<Template[Infobox]>'}
      end

      context 'explicit base option' do
        subject{set.find('Infobox cheese')}
        it{should be_a(Class)}
        it{should < set.find('Infobox')}
        its(:inspect){should == '#<Template[Infobox cheese]>'}
        its(:instance_methods){should include(:infobox?)}
      end

      context 'inflow template' do
        subject{set.find('convert')}
        it{should be_a(Class)}
        it{should < InFlowTemplate}
        its(:inspect){should == '#<InFlowTemplate[convert]>'}
      end

      context 'defaults' do
        subject{set.find('undefined')}
        it{should be_a(Class)}
        it{should == Template}
      end

      context 'helpers' do
        subject{set.find('!').new('!')}
        it{should be_kind_of(InFlowTemplate)}
        its(:text){should == '|'}
      end

      context 'redefinition' do
      end
    end
  end
end
