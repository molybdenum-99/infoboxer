module Infoboxer
  describe 'calculated templates' do
    let(:traits) { MediaWiki::Traits.get('en.wikipedia.org') }
    let(:template_vars) {
      variables.each_with_index.map { |v, i| Tree::Var.new((i + 1).to_s, Tree::Text.new(v)) }
    }

    subject { traits.templates.find(name).new(name, Tree::Nodes[*template_vars]) }

    describe '{{Convert}}' do
      let(:name) { 'Convert' }

      context 'simplest case' do
        let(:variables) { %w[120 km mi] }

        it { is_expected.to be_kind_of(Templates::Base) }

        its(:text) { is_expected.to eq '120 km' }
        its(:value1) { is_expected.to eq '120' }
        its(:value2) { is_expected.to be_nil }
        its(:measure_from) { is_expected.to eq 'km' }
        its(:measure_to) { is_expected.to eq 'mi' }
      end

      context 'with between sign' do
        let(:variables) { %w[120 × 15 m acres] }

        its(:text) { is_expected.to eq '120 × 15 m' }
        its(:value1) { is_expected.to eq '120' }
        its(:value2) { is_expected.to eq '15' }
        its(:between) { is_expected.to eq '×' }
        its(:measure_from) { is_expected.to eq 'm' }
        its(:measure_to) { is_expected.to eq 'acres' }
      end
    end

    describe '{{Coord}}' do
    end

    describe '{{Age}}' do
      let(:name) { 'Age' }

      context 'one date' do
        before { Timecop.freeze(Date.parse('2017-06-23')) }
        let(:variables) { %w[1985 07 01] }

        it { is_expected.to be_kind_of(Templates::Base) }

        its(:text) { is_expected.to eq '32 years' }
      end

      context 'two dates' do
        let(:variables) { %w[1985 07 01 1995 08 15] }

        its(:text) { is_expected.to eq '10 years' }
      end
    end

    describe '{{Birth date and age}}' do
    end

    describe '{{Birth date}}' do
    end

    describe '{{Time ago}}' do
    end
  end
end
