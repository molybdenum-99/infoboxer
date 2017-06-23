# encoding: utf-8
module Infoboxer
  module Tree
    describe Nodes do
      describe :inspect do
        subject { nodes.inspect }

        context 'by default' do
          let(:nodes) { Nodes[Text.new('some text')] }

          it { should == '[#<Text: some text>]' }
        end

        context 'really long children list' do
          let(:children) { Array.new(20) { Text.new('some text') } }
          let(:nodes) { Nodes[*children] }

          it { should == '[#<Text: some text>, #<Text: some text>, #<Text: some text>, #<Text: some text>, #<Text: some text>, ...15 more nodes]' }
        end
      end

      describe 'as Enumerable' do
        let(:nodes) { Nodes[Text.new('one'), Text.new('two')] }

        it 'should be nodes always' do
          expect(nodes.select { |n| n.text == 'one' }).to be_a(Nodes)
          expect(nodes.reject { |n| n.text == 'one' }).to be_a(Nodes)
          expect(nodes.sort_by(&:text)).to be_a(Nodes)
        end

        it 'is smart when mapping' do
          expect(nodes.map { |n| n }).to be_a(Nodes)
          expect(nodes.map(&:text)).to be_an(Array)
        end
      end

      describe :strip do
        context 'last empty texts' do
          subject { Nodes[Text.new('test'), Text.new(' ')] }
          its(:strip) { should == Nodes[Text.new('test')] }
        end

        context 'spaces in last text' do
          subject { Nodes[Text.new('test ')] }
          its(:strip) { should == Nodes[Text.new('test')] }
        end
      end

      describe :<< do
        describe 'merging' do
          context 'text' do
            context 'when previous was text' do
              subject { Nodes[Text.new('test')] }
              before {
                subject << Text.new(' me')
              }
              it { should == [Text.new('test me')] }
            end

            context 'when previous was not a text' do
              subject { Nodes[Italic.new(Text.new('test'))] }
              before {
                subject << Text.new(' me')
              }
              it { should == [Italic.new(Text.new('test')), Text.new(' me')] }
            end

            context 'when its first text' do
              subject { Nodes[] }
              before {
                subject << 'test'
              }
              it { should == [Text.new('test')] }
            end
          end

          context 'paragraphs' do
            context 'when can merge' do
              subject { Nodes[Paragraph.new(Text.new('test'))] }
              before {
                subject << Paragraph.new(Text.new('me'))
              }
              it { should == [Paragraph.new(Text.new('test me'))] }
            end

            context 'when can\'t merge' do
              subject { Nodes[Paragraph.new(Text.new('test'))] }
              before {
                subject << Pre.new(Text.new('me'))
              }
              it { should == [Paragraph.new(Text.new('test')), Pre.new(Text.new('me'))] }
            end

            context 'children\'s #parent rewriting' do
              let(:para) { Nodes[Paragraph.new(Text.new('test'))] }
              before {
                para << Paragraph.new([Text.new('me, '), Italic.new(Text.new('please'))])
              }
              subject { para.lookup(:Italic).first }
              its(:parent) { should == para.first }
            end
          end
        end

        describe 'empty paragraphs dropping' do
          context 'into paragraph' do
            subject { Nodes[Paragraph.new(Text.new('test'))] }
            before {
              subject << EmptyParagraph.new(' ')
            }
            it { should == [Paragraph.new(Text.new('test'))] }
            its(:last) { should be_closed }
          end

          context 'into pre' do
            subject { Nodes[Pre.new(Text.new('test'))] }
            before {
              subject << EmptyParagraph.new('   ')
            }
            it { should == [Pre.new(Text.new("test\n  "))] }
            its(:last) { should_not be_closed }
          end

          context 'into pre -- really empty' do
            subject { Nodes[Pre.new(Text.new('test'))] }
            before {
              subject << EmptyParagraph.new('')
            }
            it { should == [Pre.new(Text.new("test"))] }
            its(:last) { should be_closed }
          end
        end

        describe 'implicit flatten' do
          subject { Nodes[Text.new('test')] }
          before {
            subject << [Text.new(' me')]
          }
          it { should == [Text.new('test me')] }
        end

        describe 'flowing-in templates' do
          let(:nodes) { Nodes[Paragraph.new(
              [Text.new(' '),
              Template.new('one'),
              Text.new("\n"),
              Template.new('two')]),
            ]
          }
          subject { nodes.flow_templates }
          its(:count) { should == 2 }
          it { should all(be_a(Template)) }
        end

        describe 'ignoring of empty nodes' do
          context 'text' do
            subject { Nodes[Italic.new(Text.new('test'))] }
            before {
              subject << Text.new('')
            }
            it { should == [Italic.new(Text.new('test'))] }
          end

          context 'compound' do
            subject { Nodes[Paragraph.new(Text.new('test'))] }
            before {
              subject << Pre.new()
            }
            it { should == [Paragraph.new(Text.new('test'))] }
          end

          context 'but not HTML!' do
            subject { Nodes[Paragraph.new(Text.new('test'))] }
            before {
              subject << HTMLTag.new('br', {})
            }
            it { should == [Paragraph.new(Text.new('test')), HTMLTag.new('br', {})] }
          end

          context 'empty paragraphs' do
            subject { Nodes[Heading.new(Text.new('test'), 2)] }
            before {
              subject << EmptyParagraph.new(' ')
            }
            it { should == [Heading.new(Text.new('test'), 2)] }
          end
        end
      end
    end
  end
end
