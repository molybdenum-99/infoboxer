# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser, '<ref>' do
    let(:ctx){Parser::Context.new(source)}
    let(:parser){Parser.new(ctx)}

    let(:nodes){parser.inline}
    subject{nodes.first}

    context 'simple' do
      let(:source){
        "<ref>The text\nof the reference</ref>"
      }

      it{should ==
        Ref.new([
          Text.new('The text'),
          Paragraph.new(Text.new('of the reference'))
        ])
      }
    end

    context 'with params' do
      let(:source){
        "<ref name=gini>\nThe text\n\nof the reference</ref>"
      }

      it{should be_kind_of(Ref)}
      its(:params){should == {name: 'gini'}}
    end

    context 'self-closing' do
      let(:source){'<ref name=totalpop/>'}
      it{should be_kind_of(Ref)}
      its(:params){should == {name: 'totalpop'}}
    end

    context 'with incomplete markup' do
      let(:source){
        "<ref>''bad markup!</ref>"
      }

      it{should be_kind_of(Ref)}
      its(:children){should == [Italic.new(Text.new("bad markup!"))]}
    end
  end
end
