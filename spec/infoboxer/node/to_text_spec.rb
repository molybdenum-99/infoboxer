# encoding: utf-8
module Infoboxer
  describe Node do
    describe :to_text do
      context 'from node' do
        let(:text){node.to_text}
        subject{text}

        context Text do
          let(:node){Text.new('test')}

          it{should == 'test'}
        end

        context Compound do
          let(:node){Compound.new([Text.new('one'), Text.new('two')])}

          it{should == 'onetwo'}
        end

        context Paragraph do
          let(:node){Paragraph.new([Text.new('one')])}

          it{should == "one\n\n"}
        end
      end

      context 'from source' do
        let(:document){Parser.parse(unindent(source))}
        let(:text){document.to_text}
        subject{text}

        context 'simple headings and paragraphs' do
          let(:source){%Q{
            == Heading 2 ==
            === Heading 3 ===
            Paragraph.

            Other paragraph.
            Still that, other paragraph.
          }}

          it{should == 
            "Heading 2\n\n" \
            "Heading 3\n\n" \
            "Paragraph.\n\n" \
            "Other paragraph. Still that, other paragraph.\n\n"
          }
        end

        context 'lists' do
        
        end

        context 'pre' do
          let(:source){%Q{
            Here will be pre:

             First line
             Next line
            }}

          it{should == 
            "Here will be pre:\n\n" \
            "First line\n" \
            "Next line\n\n" 
          }
        end

        context 'links and other inline markup' do
        end

        context 'tables' do
        end
      end
      
    end
  end
end
