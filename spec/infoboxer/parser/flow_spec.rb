# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'parse flow' do
    let(:ctx){Parser::Context.new(source)}
    let(:parser){Parser.new(ctx)}

    describe :inline do
      subject{parser.inline}

      context 'when simple one-liner' do
        let(:source){'some text'}

        it{should == [Tree::Text.new('some text')]}

        it 'shifts parsing pointer' do
          parser.inline
          expect(ctx).to be_eof
        end
      end

      context 'when multiline without end regexp (implicit end)' do
        let(:source){"some text\nor some other text"}
        it{should == [Tree::Text.new('some text')]}
      end

      context 'when multiline with end regexp' do
        let(:source){"some text\nor some other text}}"}
        subject{parser.inline(/}}/)}

        it{should == [Tree::Text.new("some text\nor some other text")]}
      end

      context 'when multiline with end regexp not found' do
        let(:source){"some text\nor some other text"}
        it 'should fail' do
          expect{parser.inline(/}}/)}.to raise_error(Parser::ParsingError)
        end
      end
    end

    describe :short_inline do
      subject{parser.short_inline}

      context 'when simple one-liner' do
        let(:source){'some text'}

        it{should == [Tree::Text.new('some text')]}

        it 'shifts parsing pointer' do
          parser.inline
          expect(ctx).to be_eof
        end
      end

      context 'when multiline without end regexp (implicit end)' do
        let(:source){"some text\nor some other text"}
        it{should == [Tree::Text.new('some text')]}
      end

      context 'when multiline with end regexp on first line' do
        let(:source){"some}} text\nor some other text"}
        subject{parser.short_inline(/}}/)}

        it{should == [Tree::Text.new("some")]}
      end

      context 'when multiline with end regexp not found' do
        let(:source){"some text\nor some other text"}
        subject{parser.short_inline(/}}/)}

        it{should == [Tree::Text.new("some text")]}
      end

      context 'when "syntetic eol" (end of block element)' do
        let(:source){"some</ref> text\nor some other text"}
        subject{parser.short_inline(/''/)}

        it{should == [Tree::Text.new("some")]}
      end
    end

    describe :paragraphs do
      subject{parser.paragraphs}
      describe 'one-liner' do
        let(:source){"some text"}
        it{should == [Tree::Paragraph.new(Tree::Text.new('some text'))]}
      end

      describe 'continuous paragraph' do
        let(:source){"some text\nor some other text"}
        it{should == [Tree::Paragraph.new(Tree::Text.new("some text or some other text"))]}
      end

      describe 'several paragraphs' do
        let(:source){"some text\n\nor some other text"}
        it{should == [
          Tree::Paragraph.new(Tree::Text.new("some text")),
          Tree::Paragraph.new(Tree::Text.new("or some other text"))
        ]}
      end

      describe 'with end regexp' do
        let(:source){"some text\n\nor some}} other text"}
        subject{parser.paragraphs(/}}/)}
        it{should == [
          Tree::Paragraph.new(Tree::Text.new("some text")),
          Tree::Paragraph.new(Tree::Text.new("or some"))
        ]}
      end

      describe 'with end regexp - pre' do
      end
    end

    describe 'long inline' do
      subject{parser.long_inline}
      describe 'one-liner' do
        let(:source){"some text"}
        it{should == [Tree::Text.new('some text')]}
      end

      describe 'one-liner - with end regexp' do
        let(:source){"some }} text"}
        subject{parser.long_inline(/}}/)}
        it{should == [Tree::Text.new('some ')]}
      end

      describe 'inline, then paragraphs' do
        let(:source){"some text\nor some other text"}
        it{should == [Tree::Text.new("some text"), Tree::Paragraph.new(Tree::Text.new("or some other text"))]}
      end

      describe 'inline, then paragraphs - with end regexp' do
        let(:source){"some text\nor some}} other text"}
        subject{parser.long_inline(/}}/)}
        it{should == [Tree::Text.new("some text"), Tree::Paragraph.new(Tree::Text.new("or some"))]}
      end
    end
  end
end
