# encoding: utf-8
module Infoboxer
  describe Node do
    describe '#inspect' do
      subject{node.inspect}
      
      context Text do
        context 'by default' do
          let(:node){Text.new('some text')}
          
          it{should == '#<Text: "some text">'}
        end

        context 'really long text' do
          let(:str){'some text'*100}
          let(:node){Text.new(str)}
          
          it{should == "#<Text: #{str[0..30].inspect}...>"}
        end
      end
    end
  end
end
