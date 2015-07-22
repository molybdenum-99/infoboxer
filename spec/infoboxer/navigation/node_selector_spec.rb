# encoding: utf-8
module Infoboxer
  describe NodeLookup::Selector do
    context 'when class' do
      subject{described_class.new(ListItem)}

      it{should be_matches(ListItem.new(Text.new('test')))}
      it{should_not be_matches(Text.new('test'))}
    end

    context 'when class-ish symbol' do
      subject{described_class.new(:ListItem)}

      it{should be_matches(ListItem.new(Text.new('test')))}
      it{should_not be_matches(Text.new('test'))}
    end

    context 'when field value' do
      subject{described_class.new(text: /test/)}

      it{should be_matches(Text.new('test'))}
      it{should_not be_matches(Text.new('foo'))}
    end

    context 'when node-specific field' do
      subject{described_class.new(level: 3)}

      it{should be_matches(Heading.new([], 3))}
      it{should_not be_matches(Heading.new([], 2))}
      it{should_not be_matches(Text.new('foo'))}
    end

    context 'when checking method' do
      subject{described_class.new(:empty?)}

      it{should be_matches(Heading.new([], 3))}
      it{should_not be_matches(Heading.new(Text.new('test'), 2))}
    end

    context 'when block' do
      subject{described_class.new{|n| n.text.include?('foo')}}

      it{should be_matches(Text.new('foo'))}
      it{should_not be_matches(Text.new('test'))}
    end
  end
end
