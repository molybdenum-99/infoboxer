# encoding: utf-8
module Infoboxer
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

    describe 'as Enumerable' do
      let(:nodes){Nodes[Text.new('one'), Text.new('two')]}

      it 'should be nodes always' do
        expect(nodes.select{|n| n.text == 'one'}).to be_a(Nodes)
        expect(nodes.reject{|n| n.text == 'one'}).to be_a(Nodes)
        expect(nodes.sort_by(&:text)).to be_a(Nodes)
      end
    end
  end
end
