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
        
        loop do
          current = @lines.shift

          !started && current !~ /^\s*{\|/ and
            fail("Something went wrong: trying to parse not a table: #{current}")

          case current
          when /^\s*{\|(.*)$/.guard{!started} # main table start

            started = true

          when /^\s*{\|/                      # nested table start
          
            add_to_cell(TableParser.new(@lines).parse)

          when /^\s*\|}(.*)$/                 # table end

            rest = $1
            @lines.unshift rest unless rest.empty?
            break

          when /^\s*!(.*)$/                   # heading (th) in a row
            parse_cells($1, Parser::TableHeading)

          when /^\s*\|\+(.*)$/               # caption
            
            start_caption($1)
            
          when /^\s*\|-(\s*)$/                # row start
            start_row!

          when /^\s*\|(.*)$/                  # cell in row

            parse_cells($1)

          when /.*/.guard{@current_row}       # continuation of prev.cell
            @multiline << "\n#{current}"

          when nil
            fail("End of input before table ended!")

          else
            fail("Not a table: first row is #{current}")
          end
        end

        finalize_row!
        
        @table
      end

      private

      def parse_cells(str, cell_class = Parser::TableCell)
        start_row! unless @current_row
        cells = []
        
        scan = StringScanner.new(str)
        loop do
          str = scan.scan_until(/\|\|/)
          case scan.matched
          when '||'
            cells << str.sub('||', '')
          when nil
            cells << scan.rest
            break
          end
        end
        cells = cells.map{|str| cell_class.new(InlineParser.parse(str))}
        @current_row.concat(cells)
      end

      def start_caption(str)
        finalize_row!
        @is_caption = true
        @multiline << str
      end

      def start_row!
        finalize_row!
      end

      def finalize_row!
        if @current_row && !@current_row.empty?
          unless @multiline.empty?
            @current_row.last.children.concat(
              Parser.new(@multiline).parse.children
            )
          end
          
          @table.children << Parser::TableRow.new(@current_row)
        elsif @is_caption
          @table.children << Parser::TableCaption.new(InlineParser.parse(@multiline.strip))
        end

        @current_row = []
        @is_caption = false
        @multiline = ''
      end
    end
  end
end
