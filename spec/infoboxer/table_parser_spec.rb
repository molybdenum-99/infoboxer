# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser::TableParser do
    def parse_table(text)
      described_class.new(text.strip.split("\n")).parse
    end

    describe 'simplest' do
      subject{parse_table(%Q{{|
        |one
        |}})
      }

      it{should be_a(Parser::Table)}
      its(:"rows.count"){should == 1}
      it 'should contain text' do
        expect(subject.rows.first.cells.first.children).to eq \
          [Parser::Text.new('one')]
      end
    end

    describe 'multiple cells' do
      let(:table){parse_table(source)}
      let(:cells){table.rows.first.cells}
      subject{cells}
      
      context 'all cells in one line' do
        let(:source){%Q{
          {|
          |one||two||three: it's a long text, dude!
          |}
        }}
        its(:count){should == 3}
        it 'should preserve text' do
          expect(subject.map(&:text)).to eq ['one', 'two', "three: it's a long text, dude!"]
        end
      end
      
      context 'cells on separate lines' do
        let(:source){%Q{
          {|
          |one||two
          |three: it's a long text, dude!||and four
          |}
        }}
        its(:count){should == 4}
        it 'should preserve text' do
          expect(subject.map(&:text)).to eq \
            ['one', 'two', "three: it's a long text, dude!", 'and four']
        end
      end
      
      context 'multiline cells' do
        let(:source){%Q{
          {|
          |one||two
three: it's a long text, dude!||and four
          |}
        }}
        its(:count){should == 2}
        describe 'last cell' do
          subject{cells.last}
          it 'should do bad things with next lines!' do
            expect(subject.children.map(&:class)).to eq \
              [Parser::Text, Parser::Paragraph]
            expect(subject.children.map(&:text)).to eq \
              ['two', "three: it's a long text, dude!||and four"]
          end
        end
      end
    end

    describe 'multiple rows' do
    end

    describe 'table caption' do
    end

    describe 'headers' do
    end

    describe 'table-level params' do
    end

    describe 'cell-level params' do
    end

    describe 'row-level params' do
    end

    describe 'tables, Karl!' do
    end
  end
end
