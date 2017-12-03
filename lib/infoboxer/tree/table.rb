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
        children.grep(TableRow)
      end

      # Table caption, if exists.
      def caption
        children.grep(TableCaption).first
      end

      # For now, returns first table row, if it consists only of
      # {TableHeading}s.
      #
      # FIXME: it can easily be several table heading rows
      def heading_row
        rows.first if rows.first && rows.first.children.all? { |c| c.is_a?(TableHeading) }
      end

      # For now, returns all table rows except {#heading_row}
      def body_rows
        if rows.first && rows.first.children.all? { |c| c.is_a?(TableHeading) }
          rows[1..-1]
        else
          rows
        end
      end

      def text
        Terminal::Table.new.tap { |table|
          table.title = caption.text.sub(/\n+\Z/, '') if caption
          table.headings = heading_row.children.map(&:text_) if heading_row
          table.rows = body_rows.map { |r| r.children.map(&:text_) }
        }.to_s + "\n\n"
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
