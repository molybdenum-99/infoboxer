# encoding: utf-8
require 'htmlentities'

module Infoboxer
  class Parser
    class Node
      def initialize(text = '')
        @text = text
      end

      attr_reader :text
      
      def can_merge?(other)
        false
      end

      # TODO: compact inspect when long text
      def inspect
        "#<#{clean_class}: #{text}>"
      end

      def clean_class
        self.class.name.sub(/^.*::/, '')
      end
    end

    class HR < Node
      def inspect
        "#<#{clean_class}>"
      end
    end

    class Text < Node
      def self.coder
        @coder ||= HTMLEntities.new
      end
      
      def text
        self.class.coder.decode(@text)
      end
    end

    class Link < Node
      def initialize(link, label = nil)
        @link = link
        @label = label || link
      end

      attr_reader :label, :link
      alias_method :text, :label

      def inspect
        label == link ?
          "#<#{clean_class}: #{link}>" :
          "#<#{clean_class}(#{label}): #{link}>"
      end
    end

    class Wikilink < Link
    end

    class ExternalLink < Link
    end

    class Compound < Node
      def initialize(children)
        @children = children
      end

      attr_reader :children

      def text
        @children.map(&:text).join
      end

      # TODO: compact inspect when long children list
      def inspect
        "#<#{clean_class}: #{children}>"
      end

      def can_merge?(other)
        self.class == other.class && !closed?
      end

      def merge!(other)
        @text += other.text # Temp
        @closed = other.closed?
      end

      def closed!
        @closed = true
      end

      def closed?
        @closed
      end
    end

    # Inline nodes -----------------------------------------------------
    class Italic < Compound
    end

    class Bold < Compound
    end

    class BoldItalic < Compound
    end

    # HTML -------------------------------------------------------------
    class HTMLTag < Compound
      def initialize(tag, attrs, children = Nodes.new)
        @tag, @attrs = tag, attrs
        super(children)
      end

      attr_reader :tag, :attrs

      def inspect
        "#<#{clean_class}:#{tag}(#{attrs}) #{children.inspect}>"
      end
    end

    class HTMLOpeningTag < Node
      def initialize(tag, attrs)
        @tag, @attrs = tag, attrs
      end

      attr_reader :tag, :attrs

      def inspect
        "#<#{clean_class}:#{tag}(#{attrs})>"
      end
    end

    class HTMLClosingTag < Node
      def initialize(tag)
        @tag = tag
      end

      attr_reader :tag

      def inspect
        "#<#{clean_class}:#{tag}>"
      end
    end

    # Paragraph-level nodes --------------------------------------------

    class Paragraph < Compound
    end

    class Heading < Compound
      def initialize(text, level)
        super(text)
        @level = level
      end

      attr_reader :level

      def can_merge?(*)
        false
      end
    end

    class ListItem < Compound
      def initialize(text, marker)
        super(text)
        @marker = marker
      end

      attr_reader :marker
    end

    class Pre < Compound
    end
  end
end
