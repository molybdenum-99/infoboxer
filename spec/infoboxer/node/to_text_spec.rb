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
        let(:document){Parse.document(unindent(source))}
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
          context 'unordered' do
            let(:source){%Q{
              * its
              * a
              * list
            }}

            it{should ==
              "* its\n"\
              "* a\n"\
              "* list\n\n"
            }
          end

          context 'ordered' do
            let(:source){%Q{
              # its
              # a
              # list
            }}

            it{should ==
              "1. its\n"\
              "2. a\n"\
              "3. list\n\n"
            }
          end

          context 'definitions' do
            let(:source){%Q{
              ; its
              : a
              ; list
              : of defs
            }}

            it{should ==
              "its:\n"\
              "  a\n"\
              "list:\n"\
              "  of defs\n\n"
            }
          end

          context 'nest' do
            let(:source){%Q{
              * its
              ** a
              ** nested
              * list
            }}
              
            it{should ==
              "* its\n"\
              "  * a\n"\
              "  * nested\n"\
              "* list\n\n"\
            }
          end

          context 'mixing and nesting' do
            let(:source){%Q{
              * list
              * with
              *# different
              *# levels of
              *#; deep
              *#: inlining!
              * is cool

              paragraph
            }}

            it{should == 
              "* list\n" \
              "* with\n" \
              "  1. different\n" \
              "  2. levels of\n" \
              "    deep:\n" \
              "      inlining!\n" \
              "* is cool\n\n"\
              "paragraph\n\n"
            }
          end
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

        context 'tables' do
          let(:source){%Q{
            {|
            |+ Caption
            |-
            ! first
            ! row
            ! headings
            |-
            | next
            | row
            | cells
            |-
            | even
            | next
            | row
            |}
          }}

          it{should ==
            "+-------+------+----------+\n"\
            "|         Caption         |\n"\
            "+-------+------+----------+\n"\
            "| first | row  | headings |\n"\
            "+-------+------+----------+\n"\
            "| next  | row  | cells    |\n"\
            "| even  | next | row      |\n"\
            "+-------+------+----------+\n\n"
          }
        end

        context 'links and other inline markup' do
          let(:source){"one ''two'' [[named|link]] [[unnamed link]]"}
          it{should == "one two link unnamed link\n\n"}
        end

        context 'br' do
          let(:source){'one<br/>two'}
          it{should == "one\ntwo\n\n"}
        end

        context 'ref' do
          let(:source){'some text<ref>with ref</ref>'}
          it{should == "some text\n\n"}
        end

        context 'templates' do
          let(:source){"some text{{with|realy=complex ''template''}}"}
          it{should == "some text\n\n"}
        end
      end
      
    end
  end
end
