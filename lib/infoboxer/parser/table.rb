# encoding: utf-8
require 'matchish'

module Infoboxer
  class Parser
    # http://en.wikipedia.org/wiki/Help:Table
    #
    # Tables in Wikipedia are line-level formatting
    # So, TableParser receives list of lines from main Parser
    # and does many nasty things with them.
    #
    class TableParser
      def initialize(lines)
        @lines = lines
        @table = Table.new
      end

      def parse
        started = false
        @current_row = []
        
        loop do
          current = @lines.shift

          !started && current !~ /^\s*{\|/ and
            fail("Something went wrong: trying to parse not a table: #{current}")

          case current
          when /^\s*{\|(.*)$/.guard{!started}
            started = true
            #parse_table_attrs($1)

          when /^\s*{\|/
            add_to_cell(TableParser.new(@lines).parse)

          when /^\s*\|}(.*)$/
            rest = $1
            @lines.unshift rest unless rest.empty?
            break

          when /^\s*\|(.*)$/
            parse_cells($1)

          when nil
            fail("End of input before table ended!")

          else
            @current_row.last << "\n#{current}"
          end
        end

        finalize_row!
        
        @table
      end

      private

      def parse_cells(str)
        scan = StringScanner.new(str)
        loop do
          str = scan.scan_until(/\|\|/)
          case scan.matched
          when '||'
            @current_row << str.sub('||', '')
          when nil
            @current_row << scan.rest
            break
          end
        end
      end

      def finalize_row!
        unless @current_row.empty?
          cells = @current_row.map{|str| parse_cell(str)}
          @table.rows << Parser::TableRow.new(cells)
        end
      end

      # First line is just inline formatting
      # All next lines (if exist) are full-featured formatting, with
      #   paragraphs, lists, headings and so on
      def parse_cell(str)
        if str.include?("\n")
          str, r = str.split("\n", 2)
          rest = Parser.new(r).parse.children
        else
          rest = []
        end
        nodes = InlineParser.new(str).parse.concat(rest)

        Parser::TableCell.new(nodes)
      end
    end
  end
end
