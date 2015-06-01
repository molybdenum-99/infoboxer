# encoding: utf-8
require_relative 'semantic_navigation'

module Infoboxer
  class Compound < Node
    def initialize(children = Nodes.new, params = {})
      super(params)
      @children = Nodes[*children]
      @children.each(&set(parent: self))
    end

    attr_reader :children

    def empty?
      children.empty?
    end

    def index_of(child)
      children.index(child)
    end

    def push_children(*nodes)
      @children.concat(nodes.each(&set(parent: self)))
    end

    include SemanticNavigation

    def to_text
      children.map(&:to_text).join
    end

    # TODO: compact inspect when long children list
    def inspect
      "#<#{descr}: #{children}>"
    end

    def can_merge?(other)
      false
    end

    def closed!
      @closed = true
    end

    def closed?
      @closed
    end

    def to_tree(level = 0)
      if children.count == 1 && children.first.is_a?(Text)
        "#{indent(level)}#{children.first.text} <#{descr}>\n"
      else
        "#{indent(level)}<#{descr}>\n" +
          children.map(&call(to_tree: level+1)).join
      end
    end

    def _lookup_children(selector)
      @children._find(selector)
    end

    def _lookup(selector)
      Nodes[super(selector), *children._lookup(selector)].
        flatten.compact
    end

    private

    def _eq(other)
      children == other.children
    end      
  end
end

require_relative 'section'
