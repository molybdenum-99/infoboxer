# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser do
    context 'basic methods behavior' do
      let(:ctx){Parse::Context.new(source)}
      let(:parser){Parser.new(ctx)}

      describe :inline do
        subject{parser.inline}
        
        context 'when simple one-liner' do
          let(:source){'some text'}

          it{should == [Text.new('some text')]}

          it 'shifts parsing pointer' do
            parser.inline
            expect(ctx).to be_eof
          end
        end

        context 'when multiline without end regexp (implicit end)' do
          let(:source){"some text\nor some other text"}
          it{should == [Text.new('some text')]}
        end

        context 'when multiline with end regexp' do
          let(:source){"some text\nor some other text}}"}
          subject{parser.inline(/}}/)}
          
          it{should == [Text.new("some text\nor some other text")]}
        end

        context 'when multiline with end regexp not found' do
          let(:source){"some text\nor some other text"}
          it 'should fail' do
            expect{parser.inline(/}}/)}.to raise_error(Parse::ParsingError)
          end
        end
      end

      describe :short_inline do
        subject{parser.short_inline}
        
        context 'when simple one-liner' do
          let(:source){'some text'}

          it{should == [Text.new('some text')]}

          it 'shifts parsing pointer' do
            parser.inline
            expect(ctx).to be_eof
          end
        end

        context 'when multiline without end regexp (implicit end)' do
          let(:source){"some text\nor some other text"}
          it{should == [Text.new('some text')]}
        end

        context 'when multiline with end regexp on first line' do
          let(:source){"some}} text\nor some other text"}
          subject{parser.short_inline(/}}/)}
          
          it{should == [Text.new("some")]}
        end

        context 'when multiline with end regexp not found' do
          let(:source){"some text\nor some other text"}
          subject{parser.short_inline(/}}/)}
          
          it{should == [Text.new("some text")]}
        end

        context 'when "syntetic eol" (end of block element)' do
          let(:source){"some</ref> text\nor some other text"}
          subject{parser.short_inline(/''/)}
          
          it{should == [Text.new("some")]}
        end
      end
    end
  end
end
