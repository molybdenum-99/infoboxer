# encoding: utf-8
module Infoboxer
  class Parser
    # http://en.wikipedia.org/wiki/Help:Table
    module Table
      include Tree
      
      def table
         @context.current =~ /^\s*{\|/ or
          @context.fail!('Something went wrong: trying to parse not a table')

        prms = table_params
        table = Tree::Table.new(Nodes[], prms)

        @context.next!

        loop do
          table_next_line(table) or break
          @context.next!
        end

        # FIXME: not the most elegant way, huh?
        table.children.reject!{|r| r.children.empty?}

        table
      end

      def table_params
        @context.skip(/\s*{\|/)
        parse_params(@context.rest)
      end

      def table_next_line(table)
        case @context.current
        when /^\s*\|}(.*)$/                 # table end
          @context.scan(/^\s*\|}/)
          return false # should not continue

        when /^\s*!/                        # heading (th) in a row
          table_cells(table, TableHeading)

        when /^\s*\|\+/                     # caption
          table_caption(table)
          
        when /^\s*\|-(.*)$/                 # row start
          table_row(table, $1)

        when /^\s*\|/                       # cell in row
          table_cells(table)

        when /^\s*{{/                       # template can be at row level
          table_template(table)

        when nil
          @context.fail!("End of input before table ended!")

        else
          table_cell_cont(table)
        end
        true # should continue parsing
      end

      def table_row(table, param_str)
        table.push_children(TableRow.new(Nodes[], parse_params(param_str)))
      end

      def table_caption(table)
        @context.skip(/^\s*\|\+\s*/)

        children = inline(/^\s*([|!]|{\|)/)
        @context.prev! # compensate next! which will be done in table()
        table.push_children(TableCaption.new(children.strip))
      end

      def table_cells(table, cell_class = TableCell)
        table.push_children(TableRow.new()) unless table.children.last.is_a?(TableRow)
        row = table.children.last

        @context.skip(/\s*[!|]\s*/)
        guarded_loop do
          if @context.check(/[^|{|\[]+\|([^\|]|$)/)
            params = parse_params(@context.scan_until(/\|/))
          else
            params = {}
          end
          content = short_inline(/(\|\||!!)/)
          row.push_children(cell_class.new(content, params))
          break if @context.eol?
        end
      end

      def table_template(table)
        contents = paragraph(/^\s*([|!]|{\|)/).to_templates?
        
        if (row = table.children.last).is_a?(TableRow)
          if (cell = row.children.last).is_a?(BaseCell)
            cell.push_children(*contents)
          else
            row.push_children(*contents)
          end
        else
          table.push_children(*contents)
        end
      end

      # On-the-fly TableCaption creation handles (real life) case, when
      # table has "HTML caption":
      #   {|
      #   <caption>....</caption>
      #
      # Solution is NOT elegant or semantically "right", yet it works.
      # Somehow.
      #
      def table_cell_cont(table)
        container = case (last = table.children.last)
        when TableRow
          cell = last.children.last
          cell.is_a?(BaseCell) ? cell : TableCaption.new
        when TableCaption
          last
        when nil
          TableCaption.new
        else
          @context.fail!("Multiline cell inside #{last}")
        end

        container.push_children(paragraph(/^\s*([|!]|{\|)/))
        table.push_children(container) unless container.parent
      end
    end
  end
end
