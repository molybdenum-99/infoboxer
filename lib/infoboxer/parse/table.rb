# encoding: utf-8
require 'matchish'

module Infoboxer
  module Parse
    # http://en.wikipedia.org/wiki/Help:Table
    #
    # Tables in Wikipedia are line-level formatting
    # So, TableParser receives list of lines from main Parser
    # and does many nasty things with them.
    #
    class TableParser
      def initialize(context)
        @context = context
        @table = Table.new
      end

      def parse
        @started = false

        !@started && @context.current !~ /^\s*{\|/ and
          @context.fail!('Something went wrong: trying to parse not a table')

        table_params
        
        loop do
          break if process_current
          
          @context.next!
        end

        finalize_row!

        @table
      end

      private

      def process_current
        case @context.current
        when /^\s*{\|/                      # nested table start
          add_to_cell(TableParser.new(@context).parse)

        when /^\s*\|}(.*)$/                 # table end
          @context.scan(/^\s*\|}/)
          return true

        when /^\s*!/                        # heading (th) in a row
          cells(TableHeading)

        when /^\s*\|\+/                     # caption
          caption
          
        when /^\s*\|-(.*)$/                 # row start
          start_row!($1)

        when /^\s*\|/                       # cell in row
          cells

        when nil
          @context.fail!("End of input before table ended!")

        else
          @context.fail!("Unparseable table line \"#{@context.current}\"")
        end
        false
      end

      def add_to_cell(node)
        @current_row or
          @context.fail!(ParsingError, "Somethig bad in this table happens!")

        @current_row.children.last.push_children(node)
      end

      include Commons

      def cells(cell_class = TableCell)
        start_row! unless @current_row

        @context.skip(/\s*[!|]/)
        cls = []
        params = []
        param_str = ''
        
        loop do
          str = @context.scan_through_until(/\|{1,2}|$/)
          case @context.matched
          when '||',
                '' # end of line
            cls << str
            params << param_str
            param_str = ''
          when '|'
            param_str = str
          end
          
          break if @context.matched.empty?
        end

        cls = cls.zip(params).map{|str, pstr|
          cell_class.new(Parse.inline(str.strip, @context.traits)).tap{|cell|
            cell.params.update(parse_params(pstr))
          }
        }
        
        unless (last = grab_multiline).empty?
          cls.last.push_children(*Parse.paragraphs(last.join("\n"), @context.traits))
        end
        
        @current_row.push_children(*cls)
      end

      def soft_strip(str)
        str.sub(/^ +/, '')
      end

      def grab_multiline
        res = []
        until @context.next_lines.first =~ /^\s*([|!]|{\|)/
          res << @context.next_lines.first
          @context.next!
        end
        res
      end

      def table_params
        @context.skip(/\s*{\|/)
        @table.params.update(parse_params(@context.rest))
        @context.next!
      end

      def caption
        finalize_row!
        @context.skip(/^\s*\|\+\s*/)

        children = InlineParser.new(@context).parse_until(/^\s*([|!]|{\|)/)
        @context.prev!
        @table.push_children(TableCaption.new(children))
      end

      def start_row!(params_str = '')
        finalize_row!
        @current_row.params.update(parse_params(params_str))
      end

      def finalize_row!
        if @current_row && !@current_row.children.empty?
          @table.push_children(@current_row)
        end

        @current_row = TableRow.new
      end
    end
  end
end
