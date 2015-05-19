# encoding: utf-8
require 'infoboxer/parser'

class Infoboxer::Parser
  describe Nodes do
    describe '#inspect' do
      subject{nodes.inspect}
      
      context 'by default' do
        let(:nodes){Nodes[Text.new('some text')]}
        
        it{should == '[#<Text: some text>]'}
      end

      context 'really long children list' do
        let(:children){20.times.map{Text.new('some text')}}
        let(:nodes){Nodes[*children]}
        
        it{should == "[#<Text: some text>, #<Text: some text>, #<Text: some text> ...17 more]"}
      end
    end
  end
end
