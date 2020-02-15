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

        guarded_loop do
          table_next_line(table) or break
          log 'Next table row'
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
        when /^\s*\|}(.*)$/                 # table end
          @context.scan(/^\s*\|}/)
          return false
        when /^\s*!/                        # heading (th) in a row
          table_cells(table, TableHeading)
        when /^\s*\|\+/                     # caption
          table_caption(table)
        when /^\s*\|-(.*)$/                 # row start
          table_row(table, Regexp.last_match(1))

        when /^\s*\|/                       # cell in row
          table_cells(table)
        when /^\s*{{/                       # template can be at row level
          table_template(table)
        when nil
          return false
        when /^(?<level>={2,})\s*(?<text>.+?)\s*\k<level>$/ # heading implicitly closes the table
          @context.prev!
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

        params = if @context.check(/[^|{|\[]+\|([^\|]|$)/)
                   parse_params(@context.scan_until(/\|/))
                 else
                   {}
                 end

        children = inline(/^\s*([|!]|{\|)/)
        if @context.matched
          @context.unscan_matched!
          @context.prev! # compensate next! which will be done in table()
        end
        table.push_children(TableCaption.new(children.strip, params))
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

        # Note: in fact, without full template parsing, we CAN'T know what level to insert it:
        # Template can be something like <tr><td>Foo</td></tr>
        # But for consistency, we insert all templates inside the <td>, forcing this <td>
        # to exist.

        table.push_children(TableRow.new) unless table.children.last.is_a?(TableRow)
        row = table.children.last
        row.push_children(TableCell.new) unless row.children.last.is_a?(BaseCell)
        cell = row.children.last

        cell.push_children(*contents)
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
