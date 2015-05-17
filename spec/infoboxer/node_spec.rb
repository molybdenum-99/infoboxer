# encoding: utf-8
require 'infoboxer/parser'

class Infoboxer::Parser
  describe Node do
    describe '#to_tree' do
      let(:plain){node.to_tree}
      let(:indented){node.to_tree(2)}

      subject{plain}

      # Basics ---------------------------------------------------------
      context Text do
        let(:node){Text.new('test')}

        specify{
          expect(plain).to eq "test <Text>\n"
          expect(indented).to eq "    test <Text>\n"
        }
      end

      context Compound do
        let(:node){Compound.new([Text.new('one'), Text.new('two')])}

        specify{
          expect(plain).to eq "<Compound>\n  one <Text>\n  two <Text>\n"
          expect(indented).to eq \
            "    <Compound>\n      one <Text>\n      two <Text>\n"
        }
      end

      # Inline nodes ---------------------------------------------------
      context Wikilink do
        let(:node){Wikilink.new('Argentina', [Text.new('Argentinian Republic')])}

        it{should ==
          "<Wikilink(link: Argentina)>\n  Argentinian Republic <Text>\n"
        }
      end

      context Image do
        context 'without caption' do
          let(:node){Image.new('picture.jpg', width: '5', height: '6')}

          it{should ==
            "<Image(path: picture.jpg, width: 5, height: 6)>\n"
          }
        end

        context 'with caption' do
          let(:node){
            Image.new('picture.jpg', width: '5', height: '6', caption: [Text.new('Look at me')])
          }

          it{should ==
            "<Image(path: picture.jpg, width: 5, height: 6)>\n"\
            "  caption:\n"\
            "    Look at me <Text>\n"
          }
        end
      end

      #context Heading do
        #let(:node){Heading.new([Text.new('one'), Italic.new('two')])}
      #end
    end

    describe '#to_text' do
    end

    describe '#inspect' do
    end
  end
end
