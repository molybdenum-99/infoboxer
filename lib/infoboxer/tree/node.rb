# encoding: utf-8
require 'htmlentities'

module Infoboxer
  module Tree
    # This is the base class for all parse tree nodes.
    #
    # Basically, you'll
    # never create instances of this class or its descendants by yourself,
    # you will receive it from tree and use for navigations.
    #
    class Node
      include ProcMe
      
      def initialize(params = {})
        @params = params
      end

      # Hash of node "params".
      #
      # Params notin is roughly the same as tag attributes in HTML. This
      # is actual for complex nodes like images, tables, raw HTML tags and
      # so on.
      #
      # The most actual params are typically exposed by node as instance
      # methods (like {Heading#level}).
      #
      # @return [Hash]
      attr_reader :params

      # Node's parent in tree
      # @return {Node}
      attr_accessor :parent

      def ==(other)
        self.class == other.class && _eq(other)
      end

      # Position in parent's children array (zero-based)
      def index
        parent ? parent.index_of(self) : 0
      end

      # List of all sibling nodes (children of same parent)
      def siblings
        parent ? parent.children - [self] : Nodes[]
      end

      # List of siblings before this one
      def prev_siblings
        siblings.select{|n| n.index < index}
      end

      # List of siblings after this one
      def next_siblings
        siblings.select{|n| n.index > index}
      end

      # Node children list
      def children
        Nodes[] # redefined in descendants
      end

      # @private
      # Used only during tree construction in {Parser}.
      def can_merge?(other)
        false
      end

      # @private
      # Whether node is empty (definition of "empty" varies for different
      # kinds of nodes). Used mainly in {Parser}.
      def empty?
        false
      end

      # Textual representation of this node and its children, ready for
      # pretty-printing. Use it like this:
      #
      # ```ruby
      # puts page.lookup(:Paragraph).first.to_tree
      # # Prints something like
      # # <Paragraph>
      # #   This <Italic>
      # #   is <Text>
      # #   <Wikilink(link: "Argentina")>
      # #     pretty <Italic>
      # #     complicated <Text>
      # ```
      # 
      # Useful for understanding page structure, and Infoboxer's representation
      # of this structure
      def to_tree(level = 0)
        indent(level) + "<#{descr}>\n"
      end

      def inspect
        text.empty? ? "#<#{descr}>" : "#<#{descr}: #{shorten_text}>"
      end

      # Node text representation. It is defined for all nodes so, that
      # entire `Document#text` produce readable text-only representation
      # of Wiki page. Therefore, rules are those:
      # * inline-formatting nodes (text, bold, italics) just return the
      #   text;
      # * paragraph-level nodes (headings, paragraphs, lists) add `"\n\n"`
      #   after text;
      # * list items add marker before text;
      # * nodes, not belonging to "main" text flow (references, templates)
      #   produce empty text.
      #
      # If you want just the text of some heading or list item (without
      # "formatting" quircks), you can use {Node#text_} method.
      #
      def text
        '' # redefined in descendants
      end

      # "Clean" version of node text: without trailing linefeeds, list
      # markers and other things added for formatting.
      #
      def text_
        text.strip
      end

      # See {Node#text_}
      def to_s
        # just aliases will not work when #text will be redefined in subclasses
        text_
      end

      private

      MAX_CHARS = 30

      def shorten_text
        text_.length > MAX_CHARS ? text_[0..MAX_CHARS] + '...' : text_
      end

      def clean_class
        self.class.name.sub(/^.*::/, '')
      end

      def descr
        if !params || params.empty?
          "#{clean_class}"
        else
          "#{clean_class}(#{show_params})"
        end
      end

      def show_params(prms = nil)
        (prms || params).map{|k, v| "#{k}: #{v.inspect}"}.join(', ')
      end

      def indent(level)
        '  ' * level
      end

      def _eq(other)
        fail(NotImplementedError, "#_eq should be defined in subclasses")
      end

      def decode(str)
        Node.coder.decode(str)
      end
      
      class << self
        # Internal: descendandts DSL
        def def_readers(*keys)
          keys.each do |k|
            define_method(k){ params[k] }
          end
        end

        # Internal: HTML entities decoder.
        def coder
          @coder ||= HTMLEntities.new
        end
      end
    end
  end
end
