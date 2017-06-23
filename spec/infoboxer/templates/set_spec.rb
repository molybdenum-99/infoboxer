# encoding: utf-8

module Infoboxer
  describe Templates::Set do
    context 'definition' do
      let(:set) {
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
        subject { set.find('Largest cities') }
        it { is_expected.to be_a(Class) }
        it { is_expected.to be < Templates::Base }
        its(:inspect) { is_expected.to eq 'Infoboxer::Templates::Template[Largest cities]' }
        its(:instance_methods) { is_expected.to include(:city_names) }

        it 'should be case-insensitive' do
          expect(set.find('largest cities')).to eq set.find('Largest cities')
        end
      end

      context 'explicit match option' do
        subject { set.find('Infobox country') }
        it { is_expected.to be_a(Class) }
        it { is_expected.to be < Tree::Template }
        its(:inspect) { is_expected.to eq 'Infoboxer::Templates::Template[Infobox]' }
      end

      context 'explicit base option' do
        subject { set.find('Infobox cheese') }
        it { is_expected.to be_a(Class) }
        it { is_expected.to be < set.find('Infobox') }
        its(:inspect) { is_expected.to eq 'Infoboxer::Templates::Template[Infobox cheese]' }
        its(:instance_methods) { is_expected.to include(:infobox?) }
      end

      context 'defaults' do
        subject { set.find('undefined') }
        it { is_expected.to be_a(Class) }
        it { is_expected.to eq Templates::Base }
      end

      context 'helpers' do
        subject { set.find('!').new('!') }
        it { is_expected.to be_kind_of(Templates::Replace) }
        its(:text) { is_expected.to eq '|' }
      end

      context 'redefinition' do
      end
    end
  end
end
