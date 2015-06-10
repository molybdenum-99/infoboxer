# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'paragraphs' do
    let(:ctx){Parse::Context.new(source)}
    let(:parser){Parser.new(ctx)}

    let(:nodes){parser.paragraphs}

    describe 'one item' do
      subject{nodes.first}

      context 'just a para' do
        let(:source){'some text'}
        
        it{should be_a(Paragraph)}
        its(:text){should == "some text\n\n"}
      end

      context 'heading' do
        let(:source){'== Some text =='}
        
        it{should be_a(Heading)}
        its(:text){should == "Some text\n\n"}
        its(:level){should == 2}
      end

      context 'list item' do
        context 'first level' do
          let(:source){'* Some text'}
          
          it{should be_a(UnorderedList)}
          its(:'children.count'){should == 1}
          its(:children){should all(be_kind_of(ListItem))}
        end

        context 'dl/dt' do
          let(:source){'; Some text'}
          it{should == DefinitionList.new(DTerm.new(Text.new('Some text')))}
        end

        context 'dl/dd' do
          let(:source){': Some text'}
          it{should == DefinitionList.new(DDefinition.new(Text.new('Some text')))}
        end

        context 'next levels' do
          let(:source){'*#; Some text'}

          # Prepare to madness!!!
          it{should ==
            UnorderedList.new(
              ListItem.new(
                OrderedList.new(
                  ListItem.new(
                    DefinitionList.new(
                      DTerm.new(
                        Text.new('Some text')
                      )
                    )
                  )
                )
              )
            )
          }
        end
      end

      context 'hr' do
        let(:source){'--------------'}
        
        it{should be_a(HR)}
      end

      context 'pre' do
        let(:source){' i += 1'}
        
        it{should be_a(Pre)}
        its(:text){should == "i += 1\n\n"}
      end
    end

    describe 'sequence' do
      subject{nodes}

      let(:source){ "== Heading ==\nParagraph\n*List item"}

      its(:count){should == 3}
      it 'should be correct items' do
        expect(subject.map(&:class)).to eq [Heading, Paragraph, UnorderedList]
        expect(subject.map(&:text)).to eq ["Heading\n\n", "Paragraph\n\n", "* List item\n\n"]
      end
    end

    describe 'merging subsequent' do
      subject{Parse.paragraphs(source)}

      context 'paragraphs' do
        let(:source){"First para\nStill first\n\nNext para"}

        its(:count){should == 2}
        it 'should be only two of them' do
          expect(subject.map(&:text)).to eq \
            ["First para Still first\n\n", "Next para\n\n"]
        end
      end

      context 'not mergeable' do
        let(:source){"== First heading ==\n== Other heading =="}

        its(:count){should == 2}
      end
      
      context 'list' do
        let(:source){
          %Q{
            * start
            ** level two
            ** level two - same list
            *# level two - other list
            *; level two - even other, dl
            *: level two - same dl
            *:# level three - next level
            #* orphan list with second level at once
          }.strip.gsub(/\n\s+/m, "\n")
        }

        # not the most elegant way of testing trees, but still!
        it{should ==
          [
            UnorderedList.new(
              ListItem.new([
                Text.new('start'),
                UnorderedList.new([
                  ListItem.new(
                    Text.new('level two')
                  ),
                  ListItem.new(
                    Text.new('level two - same list')
                  ),
                ]),
                OrderedList.new([
                  ListItem.new(
                    Text.new('level two - other list')
                  )
                ]),
                DefinitionList.new([
                  DTerm.new(
                    Text.new('level two - even other, dl')
                  ),
                  DDefinition.new([
                    Text.new('level two - same dl'),
                    OrderedList.new(
                      ListItem.new(
                        Text.new('level three - next level')
                      )
                    )
                  ])
                ])
              ])
            ),

            OrderedList.new(
              ListItem.new(
                UnorderedList.new(
                  ListItem.new(
                    Text.new('orphan list with second level at once')
                  )
                )
              )
            )
          ]
        }
      end

      context 'complex def-list' do
        let(:source){unindent(%Q{
          :{{,}}[[Guaraní language|Guaraní]] in [[Corrientes Province]].<ref name=gn>{{cite Argentine law|jur=CN|l=5598|date=22 de octubre de 2004}}</ref>
          :{{,}}[[Kom language (South America)|Kom]], [[Moqoit language|Moqoit]] and [[Wichi language|Wichi]], in [[Chaco Province]].<ref name=kom>{{cite Argentine law|jur=CC|l=6604|bo=9092|date=28 de julio de 2010}}</ref>
        })}

        its(:first){should be_a(DefinitionList)}
      end

      xcontext 'templates-only paragraph' do
        let(:source){
          %Q{{{template}}\n\nparagraph}
        }

        it{should == [
          Template.new('template'),
          Paragraph.new(Text.new('paragraph'))
        ]}
      end

      context 'empty line' do
        let(:source){
          %Q{paragraph1\n \nparagraph2} # see the space between them?
        }

        it{should == [
          Paragraph.new(Text.new('paragraph1')),
          Paragraph.new(Text.new('paragraph2'))
        ]}
      end

      context 'empty line in pre context' do
        let(:source){
          %Q{ paragraph1\n \n paragraph2} # see the space between them?
        }

        it{should == [
          Pre.new(Text.new("paragraph1\n\nparagraph2"))
        ]}
      end

      context 'comments in document' do
        let(:source){
          "== Heading <!-- nasty comment with ''markup and [[things\n\nmany of them{{-->parsed =="
        }

        it{should == [
          Heading.new(Text.new('Heading parsed'), 2)
        ]}
      end
    end
  end
end