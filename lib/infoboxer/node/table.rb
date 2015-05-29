# encoding: utf-8
require 'terminal-table'

module Infoboxer
  class Table < Compound
    def initialize(children = Nodes.new, params = {})
      super(children)
      @params = params
    end

    attr_reader :params
    
    def rows
      children.select(&fltr(itself: TableRow))
    end

    def caption
      children.detect(&fltr(itself: TableCaption))
    end

    def heading_row
      rows.first.children.all?(&call(matches?: TableHeading)) ?
        rows.first : nil
    end

    def body_rows
      rows.first.children.all?(&call(matches?: TableHeading)) ?
        rows[1..-1] :
        rows
    end

    def to_text
      table = Terminal::Table.new
      if caption
        table.title = caption.to_text.sub(/\n+\Z/, '')
      end
      
      if heading_row
        table.headings = heading_row.children.map(&:to_text).
          map(&call(sub: [/\n+\Z/, '']))
      end

      table.rows = body_rows.map{|r|
        r.children.map(&:to_text).
          map(&call(sub: [/\n+\Z/, '']))
      }
      table.to_s + "\n\n"
    end
  end

  class TableRow < Compound
    def initialize(children = Nodes.new, params = {})
      super(children)
      @params = params
    end

    attr_reader :params

    alias_method :cells, :children
  end

  class TableCell < Compound
    def initialize(children = Nodes.new, params = {})
      super(children)
      @params = params
    end

    attr_reader :params
  end

  class TableHeading < TableCell
  end

  class TableCaption < Compound
  end
end
