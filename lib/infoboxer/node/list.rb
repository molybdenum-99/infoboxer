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

    def to_text
      parent.make_marker(self) + if children.last.is_a?(List)
        children[0..-2].map(&:to_text).join + "\n" + children.last.to_text
      else
        children.map(&:to_text).join + "\n"
      end
    end
  end

  class List < Compound
    def list_level
      lookup_parent(List).count
    end

    def list_text_indent
      '  ' * list_level
    end

    def to_text
      if list_level.zero?
        super.sub(/\n+\Z/, "\n\n")
      else
        super.sub(/\n+\Z/, "\n")
      end
    end
  end

  class UnorderedList < List
    def make_marker(item)
      list_text_indent + '* '
    end
  end

  class OrderedList < List
    def make_marker(item)
      list_text_indent + "#{(item.index + 1)}. "
    end
  end

  class DefinitionList < List
    def make_marker(item)
      case item
      when DTerm
        list_text_indent
      when DDefinition
        list_text_indent + '  '
      end
    end
  end

  class DTerm < ListItem
    def to_text
      super.sub("\n", ":\n")
    end
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
