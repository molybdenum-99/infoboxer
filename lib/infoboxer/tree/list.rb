# encoding: utf-8
module Infoboxer
  module Tree
    # Represents item of ordered or unordered list.
    class ListItem < BaseParagraph
      # @private
      # Internal, used by {Parser}
      def can_merge?(other)
        other.class == self.class &&
          other.children.first.is_a?(List)
      end

      # @private
      # Internal, used by {Parser}
      def merge!(other)
        ochildren = other.children.dup
        if children.last && children.last.can_merge?(ochildren.first)
          children.last.merge!(ochildren.shift)
        end
        push_children(*ochildren)
      end

      def text
        make_marker +
          if children.last.is_a?(List)
            children[0..-2].map(&:text).join + "\n" + children.last.text
          else
            children.map(&:text).join + "\n"
          end
      end

      private

      def make_marker
        parent ? parent.make_marker(self) : '* '
      end
    end

    # "Imaginary" node, grouping {ListItem}s of same level and type.
    #
    # Base for concrete {OrderedList}, {UnorderedList} and {DefinitionList}.
    #
    # NB: Nested lists are represented by structures like:
    #
    # ```
    # <OrderedList>
    #  <ListItem>
    #  <ListItem>
    #    <Text>
    #    <UnorderedList>
    #      <ListItem>
    #      <ListItem>
    # ...and so on
    # ```
    class List < Compound
      def list_level
        lookup_parents(List).count
      end

      def list_text_indent
        '  ' * list_level
      end

      def text
        if list_level.zero?
          super.sub(/\n+\Z/, "\n\n")
        else
          super.sub(/\n+\Z/, "\n")
        end
      end
    end

    # Represents unordered list (list with markers).
    class UnorderedList < List
      def make_marker(_item)
        list_text_indent + '* '
      end
    end

    # Represents ordered list (list with numbers).
    class OrderedList < List
      def make_marker(item)
        list_text_indent + "#{(item.index + 1)}. "
      end
    end

    # Represents definitions list (`term: definition`  structure),
    # consists of {DTerm}s and {DDefinition}s.
    #
    # NB: In fact, at least in English Wikipedia, orphan "definition terms"
    # are used as a low-level headers, especially in lists of links/references.
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

    # Term in {DefinitionList}
    class DTerm < ListItem
      def text
        super.sub("\n", ":\n")
      end
    end

    # Term definition in {DefinitionList}
    class DDefinition < ListItem
    end

    class List < Compound
      include Mergeable

      # @private
      # Internal, used by {Parser}
      def merge!(other)
        ochildren = other.children.dup
        if children.last && ochildren.first &&
           children.last.can_merge?(ochildren.first)

          children.last.merge!(ochildren.shift)
        end

        push_children(*ochildren)
      end

      # @private
      # Internal, used by {Parser}
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

      # @private
      LISTS = {
        ';' => DefinitionList,
        ':' => DefinitionList,
        '*' => UnorderedList,
        '#' => OrderedList
      }.freeze

      # @private
      ITEMS = {
        ';' => DTerm,
        ':' => DDefinition,
        '*' => ListItem,
        '#' => ListItem
      }.freeze
    end
  end
end
