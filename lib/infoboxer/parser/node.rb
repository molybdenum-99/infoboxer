# encoding: utf-8
require 'htmlentities'

module Infoboxer
  class Parser
    # Base abstract classes
    class Node
      include ProcMe
      
      def initialize(params = {})
        @params = params
      end

      attr_reader :params
      
      def can_merge?(other)
        false
      end

      def ==(other)
        self.class == other.class && _eq(other)
      end

      def to_tree(level = 0)
        "<#{descr}>\n"
      end

      private

      def clean_class
        self.class.name.sub(/^.*::/, '')
      end

      def descr
        if params.empty?
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
        def def_readers(*keys)
          keys.each do |k|
            define_method(k){ params[k] }
          end
        end

        def coder
          @coder ||= HTMLEntities.new
        end
      end
    end

    class Text < Node
      def initialize(text, params = {})
        super(params)
        @text = decode(text)
      end

      attr_reader :text

      # TODO: compact inspect when long text
      def inspect
        "#<#{descr}: #{text}>"
      end

      def to_tree(level = 0)
        "#{indent(level)}#{text} <#{descr}>\n"
      end

      private

      def _eq(other)
        text == other.text
      end
    end

    class Compound < Node
      def initialize(children = Nodes.new, params = {})
        super(params)
        @children = children
      end

      attr_reader :children

      def text
        children.map(&:text).join
      end

      # TODO: compact inspect when long children list
      def inspect
        "#<#{descr}: #{children}>"
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
        "#{indent(level)}<#{descr}>\n" +
          children.map(&call(to_tree: level+1)).join
      end

      private

      def _eq(other)
        children == other.children
      end      
    end

    # Inline nodes -----------------------------------------------------
    class Italic < Compound
    end

    class Bold < Compound
    end

    class BoldItalic < Compound
    end

    class Link < Compound
      def initialize(link, label = nil)
        super(label || Nodes.new([Text.new(link)]), link: link)
      end

      def_readers :link
    end

    class Wikilink < Link
    end

    class ExternalLink < Link
    end

    class Image < Node
      def initialize(path, params = {})
        @caption = params.delete(:caption)
        super({path: path}.merge(params))
      end

      attr_reader :caption

      def_readers :path, :type,
        :location, :alignment, :link,
        :alt

      def border?
        !params[:border].to_s.empty?
      end

      def width
        params[:width].to_i
      end

      def height
        params[:height].to_i
      end

      def to_tree(level = 0)
        super(level) +
          if caption && !caption.empty?
            indent(level+1) + "caption:\n" +
              caption.map(&call(to_tree: level+2)).join
          else
            ''
          end
      end
    end

    # HTML -------------------------------------------------------------
    class HTMLTag < Compound
      def initialize(tag, attrs, children = Nodes.new)
        super(children, attrs)
        @tag = tag
      end

      attr_reader :tag
      alias_method :attrs, :params

      private

      def descr
        "#{clean_class}:#{tag}(#{show_params})"
      end
    end

    class HTMLOpeningTag < Node
      def initialize(tag, attrs)
        super(attrs)
        @tag = tag
      end
      
      attr_reader :tag
      alias_method :attrs, :params

      private

      def descr
        "#{clean_class}:#{tag}(#{show_params})"
      end
    end

    class HTMLClosingTag < Node
      def initialize(tag)
        @tag = tag
      end

      attr_reader :tag

      def descr
        "#{clean_class}:#{tag}"
      end
    end

    # Paragraph-level nodes --------------------------------------------
    class Paragraph < Compound
    end

    class HR < Node
    end

    class Heading < Compound
      def initialize(children, level)
        super(children, level: level)
      end

      def_readers :level

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

    # Tables -----------------------------------------------------------
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
end
