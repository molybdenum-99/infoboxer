module Infoboxer
  describe Navigation::Lookup::Selector do
    context 'when class' do
      subject { described_class.new(Tree::ListItem) }

      it { is_expected.to be === Tree::ListItem.new(Tree::Text.new('test')) }
      it { is_expected.not_to be === Tree::Text.new('test') }
    end

    context 'when class-ish symbol' do
      subject { described_class.new(:ListItem) }

      it { is_expected.to be === Tree::ListItem.new(Tree::Text.new('test')) }
      it { is_expected.not_to be === Tree::Text.new('test') }
    end

    context 'when field value' do
      subject { described_class.new(text: /test/) }

      it { is_expected.to be === Tree::Text.new('test') }
      it { is_expected.not_to be === Tree::Text.new('foo') }
    end

    context 'when string' do
      subject { described_class.new(text: 'test') }

      it { is_expected.to be === Tree::Text.new('Test') }
      it { is_expected.not_to be === Tree::Text.new('foo') }
    end

    context 'when node-specific field' do
      subject { described_class.new(level: 3) }

      it { is_expected.to be === Tree::Heading.new([], 3) }
      it { is_expected.not_to be === Tree::Heading.new([], 2) }
      it { is_expected.not_to be === Tree::Text.new('foo') }
    end

    context 'when checking method' do
      subject { described_class.new(:empty?) }

      it { is_expected.to be === Tree::Heading.new([], 3) }
      it { is_expected.not_to be === Tree::Heading.new(Tree::Text.new('test'), 2) }
    end

    context 'when block' do
      subject { described_class.new { |n| n.text.include?('foo') } }

      it { is_expected.to be === Tree::Text.new('foo') }
      it { is_expected.not_to be === Tree::Text.new('test') }
    end
  end
end
