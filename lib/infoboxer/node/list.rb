# encoding: utf-8
module Infoboxer
  class ListItem < BaseParagraph
    def can_merge?(other)
      other.class == self.class &&
        other.children.first.kind_of?(List)
    end

    def merge!(other)
      ochildren = other.children.dup
      if children.last && children.last.can_merge?(ochildren.first)
        children.last.merge!(ochildren.shift)
      end
      push_children(*ochildren)
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

      push_children(*ochildren)
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
end
