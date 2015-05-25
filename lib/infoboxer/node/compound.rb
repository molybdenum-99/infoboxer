# encoding: utf-8
module Infoboxer
  class Compound < Node
    def initialize(children = Nodes.new, params = {})
      super(params)
      @children = Nodes[*children]
    end

    attr_reader :children

    def lookup_child(*arg, &block)
      @children.select{|c| c.matches?(*arg, &block)}
    end

    def text
      children.map(&:text).join
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

    def lookup(*args, &block)
      Nodes[super(*args, &block), children.map{|c| c.lookup(*args, &block)}].flatten.compact
    end

    private

    def _eq(other)
      children == other.children
    end      
  end
end
