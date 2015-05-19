# encoding: utf-8
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
