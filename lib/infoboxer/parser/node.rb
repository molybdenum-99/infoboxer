# encoding: utf-8
require 'htmlentities'

module Infoboxer
  class Parser
    class Node
      include ProcMe
      
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

      def ==(other)
        self.class == other.class && _eq(other)
      end

      def _eq(other)
        text == other.text
      end

      def to_tree(level = 0)
        '  ' * level + "#{text}   <#{clean_class}>\n"
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
        @children.concat(other.children)
        @closed = other.closed?
      end

      def closed!
        @closed = true
      end

      def closed?
        @closed
      end

      def to_tree(level = 0)
        super(level) + children.map(&call(to_tree: level+1)).join
      end
    end

    # Inline nodes -----------------------------------------------------
    class Italic < Compound
    end

    class Bold < Compound
    end

    class BoldItalic < Compound
    end

    class Image < Node
      def initialize(path, attrs = {})
        @path, @attrs = path, attrs
      end

      attr_reader :path, :attrs

      def type
        attrs[:type]
      end
      def border?
        !attrs[:border].to_s.empty?
      end
      def location
        attrs[:location]
      end
      def alignment
        attrs[:alignment]
      end
      def width
        attrs[:width].to_i
      end
      def height
        attrs[:height].to_i
      end
      def link
        attrs[:linkd]
      end
      def alt
        attrs[:alt]
      end
      def caption
        attrs[:caption] || Nodes.new
      end

      def inspect
        "#<#{clean_class}: #{path} (#{attrs.inspect})>"
      end
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

    # Templates --------------------------------------------------------
    class Template < Node
      def initialize(name, variables)
        @name, @variables = name, variables
      end

      attr_reader :name, :variables

      def inspect
        "#<#{clean_class}:#{name}#{variables}>"
      end

      def to_tree(level = 0)
        '  ' * level + "#{clean_class}:#{name}\n" +
          variables.map{|v| var_to_tree(v, level+1)}.join
      end

      def var_to_tree(var, level)
        case var
        when Hash
          '  ' * level + "| #{var.keys.first}\n" +
            var.values.first.map{|v| v.to_tree(level+1)}.join
        when Nodes
          '  ' * level + "|\n" +
            var.map{|v| v.to_tree(level+1)}.join
        end
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
