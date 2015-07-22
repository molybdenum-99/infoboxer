# encoding: utf-8
module Infoboxer
  class Compound < Node
    def initialize(children = Nodes.new, params = {})
      super(params)
      @children = Nodes[*children]
      @children.each{|c| c.parent = self}
    end

    attr_reader :children

    def empty?
      children.empty?
    end

    def index_of(child)
      children.index(child)
    end

    def push_children(*nodes)
      nodes.each{|c| c.parent = self}.each do |n|
        @children << n
      end
    end

    def text
      children.map(&:text).join
    end

    def inspect(depth = 0)
      "#<#{descr}: #{children.inspect_no_p(depth)}>"
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

    private

    def _eq(other)
      children == other.children
    end      
  end
end
