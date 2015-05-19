# encoding: utf-8
module Infoboxer
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
      if children.count == 1 && children.first.is_a?(Text)
        "#{indent(level)}#{children.first.text} <#{descr}>\n"
      else
        "#{indent(level)}<#{descr}>\n" +
          children.map(&call(to_tree: level+1)).join
      end
    end

    private

    def _eq(other)
      children == other.children
    end      
  end
end
