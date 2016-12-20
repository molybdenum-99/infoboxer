# encoding: utf-8
module Infoboxer
  module Tree
    # Base class for all nodes with children.
    class Compound < Node
      def initialize(children = Nodes.new, params = {})
        super(params)
        @children = Nodes[*children]
        @children.each { |c| c.parent = self }
      end

      # List of children
      #
      # @return {Nodes}
      attr_reader :children

      # Index of provided node in children list
      #
      # @return [Fixnum] or `nil` if not a child
      def index_of(child)
        children.index(child)
      end

      # @private
      # Internal, used by {Parser}
      def push_children(*nodes)
        nodes.each { |c| c.parent = self }.each do |n|
          @children << n
        end
      end

      # See {Node#text}
      def text
        children.map(&:text).join(children_separator)
      end

      # See {Node#to_tree}
      def to_tree(level = 0)
        if children.count == 1 && children.first.is_a?(Text)
          "#{indent(level)}#{children.first.text} <#{descr}>\n"
        else
          "#{indent(level)}<#{descr}>\n" +
            children.map(&call(to_tree: level+1)).join
        end
      end

      # Kinda "private" methods, used by Parser only -------------------

      # @private
      # Internal, used by {Parser}
      def can_merge?(_other)
        false
      end

      # @private
      # Internal, used by {Parser}
      def closed!
        @closed = true
      end

      # @private
      # Internal, used by {Parser}
      def closed?
        @closed
      end

      # @private
      # Internal, used by {Parser}
      def empty?
        children.empty?
      end

      protected

      def children_separator
        ''
      end

      private

      def _eq(other)
        children == other.children
      end
    end
  end
end
