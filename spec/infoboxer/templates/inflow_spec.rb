# encoding: utf-8
module Infoboxer
  module Tree
    describe InFlowTemplate do
      let(:node){
        Paragraph.new(
          [
            Text.new('one '),
            InFlowTemplate.new('tpl', [
              Var.new('1', Italic.new(Text.new('two'))),
              Var.new('2', Bold.new(Text.new('three'))),
              Var.new('df', Text.new('foo'))
            ])
          ]
        )
      }
      
      context 'navigation' do
        it 'should lookup inside unnamed vars' do
          expect(node.lookup(Italic)).to eq [Italic.new(Text.new('two'))]
        end

        it 'should not lookup inside named vars' do
          expect(node.lookup(text: 'foo')).to be_empty
        end
      end

      context 'text' do
        subject{node.text}
        it{should == "one two three\n\n"}
      end
    end
  end
end
