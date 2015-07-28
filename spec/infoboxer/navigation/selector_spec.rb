# encoding: utf-8
module Infoboxer
  describe Navigation::Lookup::Selector do
    context 'when class' do
      subject{described_class.new(Tree::ListItem)}

      it{should be_matches(Tree::ListItem.new(Tree::Text.new('test')))}
      it{should_not be_matches(Tree::Text.new('test'))}
    end

    context 'when class-ish symbol' do
      subject{described_class.new(:ListItem)}

      it{should be_matches(Tree::ListItem.new(Tree::Text.new('test')))}
      it{should_not be_matches(Tree::Text.new('test'))}
    end

    context 'when field value' do
      subject{described_class.new(text: /test/)}

      it{should be_matches(Tree::Text.new('test'))}
      it{should_not be_matches(Tree::Text.new('foo'))}
    end

    context 'when node-specific field' do
      subject{described_class.new(level: 3)}

      it{should be_matches(Tree::Heading.new([], 3))}
      it{should_not be_matches(Tree::Heading.new([], 2))}
      it{should_not be_matches(Tree::Text.new('foo'))}
    end

    context 'when checking method' do
      subject{described_class.new(:empty?)}

      it{should be_matches(Tree::Heading.new([], 3))}
      it{should_not be_matches(Tree::Heading.new(Tree::Text.new('test'), 2))}
    end

    context 'when block' do
      subject{described_class.new{|n| n.text.include?('foo')}}

      it{should be_matches(Tree::Text.new('foo'))}
      it{should_not be_matches(Tree::Text.new('test'))}
    end
  end
end
