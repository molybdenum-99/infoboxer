# encoding: utf-8
module Infoboxer
  module Mergeable
    def can_merge?(other)
      self.class == other.class && !closed?
    end

    def merge!(other)
      @children.concat(other.children)
      @closed = other.closed?
    end
  end
  
  class Paragraph < Compound
    include Mergeable
  end

  class HR < Node
  end

  class Heading < Compound
    def initialize(children, level)
      super(children, level: level)
    end

    def_readers :level
  end

  class ListItem < Compound
    def can_merge?(other)
      other.class == self.class &&
        other.children.first.kind_of?(List)
    end

    def merge!(other)
      ochildren = other.children.dup
      if children.last && children.last.can_merge?(ochildren.first)
        children.last.merge!(ochildren.shift)
      end
      children.concat(ochildren)
    end
  end

  class List < Compound
  end

  class UnorderedList < List
  end

  class OrderedList < List
  end

  class DefinitionList < List
  end

  class DTerm < ListItem
  end

  class DDefinition < ListItem
  end

  class List < Compound
    LISTS = {
      ';' => DefinitionList,
      ':' => DefinitionList,
      '*' => UnorderedList,
      '#' => OrderedList
    }

    ITEMS = {
      ';' => DTerm,
      ':' => DDefinition,
      '*' => ListItem,
      '#' => ListItem
    }

    include Mergeable

    def merge!(other)
      ochildren = other.children.dup
      if children.last && ochildren.first &&
        children.last.can_merge?(ochildren.first)

        children.last.merge!(ochildren.shift)
      end

      children.concat(ochildren)
    end

    def self.construct(marker, nodes)
      m = marker.shift
      klass = LISTS[m] or
        fail("Something went wrong: undefined list marker type #{m}")
      item_klass = ITEMS[m]
      
      if marker.empty?
        klass.new(item_klass.new(nodes))
      else
        klass.new(item_klass.new(construct(marker, nodes)))
      end
    end
  end

  class Pre < Compound
    include Mergeable
  end
end
