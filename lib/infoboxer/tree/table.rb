# encoding: utf-8
require 'terminal-table'

module Infoboxer
  module Tree
    # Represents table. Tables are complicated!
    class Table < Compound
      # Internal, used by {Parser}
      def empty?
        false
      end

      # All table rows.
      def rows
        children.select(&fltr(itself: TableRow))
      end

      # Table caption, if exists.
      def caption
        children.detect(&fltr(itself: TableCaption))
      end

      # For now, returns first table row, if it consists only of
      # {TableHeading}s.
      #
      # FIXME: it can easily be several table heading rows
      def heading_row
        rows.first.children.all?(&call(matches?: TableHeading)) ?
          rows.first : nil
      end

      # For now, returns all table rows except {#heading_row}
      def body_rows
        rows.first.children.all?(&call(matches?: TableHeading)) ?
          rows[1..-1] :
          rows
      end

      def text
        table = Terminal::Table.new
        if caption
          table.title = caption.text.sub(/\n+\Z/, '')
        end
        
        if heading_row
          table.headings = heading_row.children.map(&:text).
            map(&call(sub: [/\n+\Z/, '']))
        end

        table.rows = body_rows.map{|r|
          r.children.map(&:text).
            map(&call(sub: [/\n+\Z/, '']))
        }
        table.to_s + "\n\n"
      end
    end

    # Represents one table row.
    class TableRow < Compound
      alias_method :cells, :children

      def empty?
        false
      end
    end

    # Represents any table cell, either {TableCell cell} or
    # {TableHeading heading}.
    #
    # Can be used for lookups (same way as {BaseParagraph}).
    class BaseCell < Compound
      def empty?
        false
      end
    end

    # Represents ordinary table cell (`td` in HTML).
    class TableCell < BaseCell
    end

    # Represents table heading cell (`th` in HTML).
    class TableHeading < BaseCell
    end

    # Represents table caption.
    class TableCaption < Compound
    end
  end
end
