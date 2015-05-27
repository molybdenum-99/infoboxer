# encoding: utf-8
module Infoboxer
  describe Wikilink do
    context :namespace do
      context 'when no' do
        subject{Wikilink.new('Test')}
        its(:name){should == 'Test'}
        its(:namespace){should == ''}
      end

      context 'when exists' do
        subject{Wikilink.new('Category:Test')}
        its(:name){should == 'Test'}
        its(:namespace){should == 'Category'}
      end

      # TODO: check how Wikipedia thinks about it, internally!
      context 'when deeper' do
      end
    end
  end
end
