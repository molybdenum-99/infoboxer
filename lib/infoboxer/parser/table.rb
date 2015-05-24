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
      def self.parse(*arg)
        new(*arg).parse
      end
      
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
            parse_table_params(Matchish.last_match[1])

          when /^\s*{\|/                      # nested table start
          
            add_to_cell(TableParser.new(@lines).parse)

          when /^\s*\|}(.*)$/                 # table end

            rest = $1
            @lines.unshift rest unless rest.empty?
            break

          when /^\s*!(.*)$/                   # heading (th) in a row
            parse_cells($1, TableHeading)

          when /^\s*\|\+(.*)$/               # caption
            
            start_caption($1)
            
          when /^\s*\|-(.*)$/                # row start
            start_row!($1)

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

      include Commons

      def push_cell(cells, str, continued)
        if continued
          cells.last << str
        else
          cells << str
        end
      end

      def parse_cells(str, cell_class = TableCell)
        start_row! unless @current_row
        cells = []
        params = []
        param_str = ''
        continued = false
        
        scan = StringScanner.new(str)
        loop do
          str = scan.scan_until(/{{|\[\[|\|\||\|/)
          case scan.matched
          when '{{'
            push_cell(cells, str, continued)
            cells.last << scan_continued(scan, /{{/, /}}/, @lines) << '}}'
            continued = true
          when '[['
            push_cell(cells, str, continued)
            cells.last << scan_continued(scan, /\[\[/, /\]\]/, @lines) << ']]'
            continued = true
          when '||'
            push_cell(cells, str.sub('||', ''), continued)
            params << param_str
            param_str = ''
            continued = false
          when '|'
            param_str = str.sub('|', '')
          when nil
            push_cell(cells, scan.rest, continued)
            params << param_str
            break
          end
        end

        cells = cells.zip(params).map{|str, pstr|
          cell_class.new(InlineParser.parse(str)).tap{|cell|
            cell.params.update(parse_params(pstr))
          }
        }
        
        @current_row.children.concat(cells)
      end

      include Commons

      def parse_table_params(str)
        @table.params.update(parse_params(str))
      end

      def start_caption(str)
        finalize_row!
        @is_caption = true
        @multiline << str
      end

      def start_row!(params_str = '')
        finalize_row!
        @current_row.params.update(parse_params(params_str))
      end

      def finalize_row!
        if @current_row && !@current_row.children.empty?
          unless @multiline.empty?
            @current_row.children.last.children.concat(
              Parser.new(@multiline).parse.children
            )
          end
          
          @table.children << @current_row
        elsif @is_caption
          @table.children << TableCaption.new(InlineParser.parse(@multiline.strip))
        end

        @current_row = TableRow.new
        @is_caption = false
        @multiline = ''
      end

      def scan(before, after)
        res = ''
        level = 1

        before_or_after = Regexp.union(before, after)

        loop do
          str = scanner.scan_until(before_or_after)
          res << str if str

          case scanner.matched
          when before
            level += 1
          when after
            level -= 1
            
            break if level.zero?
          when nil
            
            # not finished on this line, look at next
            @next_lines.empty? and fail("Can't find #{after} for #{before}, #{res}")
            scanner << "\n" << @lines.shift
          end
        end
        res.sub(/#{after}\Z/, '')
      end
    end
  end
end
