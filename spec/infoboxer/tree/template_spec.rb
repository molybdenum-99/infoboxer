# encoding: utf-8

module Infoboxer
  module Tree
    describe Template do
      let(:template) { Parser.inline(unindent(source)).first }

      describe 'variables as params' do
        let(:source) {
          %{
          {{some template|lang=en|wtf|text=not a ''parameter''}}
        }}

        subject { template.params }

        it { is_expected.to eq(lang: 'en', :'1' => 'wtf') }
      end

      describe :fetch do
        let(:source) { File.read('spec/fixtures/large_infobox.txt') }

        context 'one value by string' do
          subject { template.fetch('conventional_long_name') }

          it { is_expected.to be_a(Tree::Nodes) }
          its(:count) { is_expected.to eq 1 }
          its(:text) { is_expected.to start_with 'Argentine Republic' }
        end

        context 'multiple values by regexp' do
          subject { template.fetch(/leader_title\d+/) }

          its(:count) { is_expected.to eq 3 }
          it { is_expected.to all(be_a(Tree::Var)) }
          it 'should be all variables queried' do
            expect(subject.map(&:name)).to eq %w[leader_title1 leader_title2 leader_title3]
          end
        end

        context 'multiple values by list' do
          subject { template.fetch('leader_title1', 'leader_name1') }

          its(:count) { is_expected.to eq 2 }
          it 'should be all variables queried' do
            expect(subject.map(&:name)).to eq %w[leader_title1 leader_name1]
          end
        end

        context 'when non-existing' do
          subject { template.fetch('something strange') }

          it { is_expected.to be_a(Tree::Nodes) }
          it { is_expected.to be_empty }
        end
      end

      context :fetch_hash do
        let(:source) { File.read('spec/fixtures/large_infobox.txt') }

        subject { template.fetch_hash('leader_title1', 'leader_name1') }

        it { is_expected.to be_a(Hash) }
        its(:keys) { is_expected.to eq %w[leader_title1 leader_name1] }
        its(:values) { is_expected.to all(be_a(Tree::Var)) }
      end

      context :fetch_date do
        let(:source) { '{{birth date and age|1953|2|19|df=y}}' }

        subject { template.fetch_date('1', '2', '3') }

        it { is_expected.to eq Date.new(1953, 2, 19) }

        context 'when no date' do
          subject { template.fetch_date('4', '5', '6') }

          it { is_expected.to be_nil }
        end
      end

      context :fetch_latlng do
      end

      describe :to_h do
        let(:source) { File.read('spec/fixtures/large_infobox.txt') }

        subject { template.to_h }

        it {
          is_expected.to include(
            'conventional_long_name' => start_with('Argentine Republic'),
            'capital' => 'Buenos Aires',
            'government_type' => 'Federal presidential constitutional republic'
            # ...and so on
          )
        }
      end
    end
  end
end
