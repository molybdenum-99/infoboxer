# encoding: utf-8
module Infoboxer
  class Parser
    # http://en.wikipedia.org/wiki/Help:Table
    module Table
      include Tree

      def table
        @context.current =~ /^\s*{\|/ or
          @context.fail!('Something went wrong: trying to parse not a table')

        log 'Starting to parse table'

        prms = table_params
        log "Table params found #{prms}"
        table = Tree::Table.new(Nodes[], prms)

        @context.next!

        loop do
          table_next_line(table) or break
          @context.next!
        end

        # FIXME: not the most elegant way, huh?
        table.children.reject! { |r| r.children.empty? }

        table
      end

      def table_params
        @context.skip(/\s*{\|/)
        parse_params(@context.rest)
      end

      def table_next_line(table)
        case @context.current
        when /^\s*\|}(.*)$/ # table end
          @context.scan(/^\s*\|}/)
          # should not continue
          return false
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
          return false
        else
          return table_cell_cont(table)
        end
        true # should continue parsing
      end

      def table_row(table, param_str)
        log 'Table row found'
        table.push_children(TableRow.new(Nodes[], parse_params(param_str)))
      end

      def table_caption(table)
        log 'Table caption found'
        @context.skip(/^\s*\|\+\s*/)

        children = inline(/^\s*([|!]|{\|)/)
        @context.prev! if @context.eol? # compensate next! which will be done in table()
        table.push_children(TableCaption.new(children.strip))
      end

      def table_cells(table, cell_class = TableCell)
        log 'Table cells found'
        table.push_children(TableRow.new) unless table.children.last.is_a?(TableRow)
        row = table.children.last

        @context.skip(/\s*[!|]\s*/)
        guarded_loop do
          params = if @context.check(/[^|{|\[]+\|([^\|]|$)/)
                     parse_params(@context.scan_until(/\|/))
                   else
                     {}
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

      # Good news, everyone! Table can be IMPLICITLY closed when it's
      # not "cell" context.
      #
      # Unless it's empty row, which is just skipped.
      def table_cell_cont(table)
        container = case (last = table.children.last)
                    when TableRow
                      last.children.last
                    when TableCaption
                      last
                    else
                      nil
                    end

        unless container
          # return "table not continued" unless row is empty
          return true if @context.current.empty?
          @context.prev!
          return false
        end

        container.push_children(paragraph(/^\s*([|!]|{\|)/))
        table.push_children(container) unless container.parent
        true
      end
    end
  end
end
