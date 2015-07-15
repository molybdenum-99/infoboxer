# encoding: utf-8
module Infoboxer
  class Section < Compound
    def initialize(heading, children = Nodes[])
      # no super: we don't wont to rewriter children's parent
      @children = Nodes[*children]
      @heading = heading
    end

    attr_reader :heading

    def push_children(*nodes)
      nodes.each do |n|
        @children << n
      end
    end

    def empty?
      false
    end

    include SectionsNavigation
  end
end
