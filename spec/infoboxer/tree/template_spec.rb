# encoding: utf-8
module Infoboxer
  module Tree
    describe Template do
      let(:template){Parser.inline(unindent(source)).first}
      
      describe 'variables as params' do
        let(:source){%Q{
          {{some template|lang=en|wtf|text=not a ''parameter''}}
        }}

        subject{template.params}
        it{should == {'lang' => 'en', '2' => 'wtf'}}
      end
    end
  end
end
