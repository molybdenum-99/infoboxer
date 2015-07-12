# encoding: utf-8
module Infoboxer
  class Section < Compound
    def initialize(heading, children = Nodes[])
      super(children)
      
      @heading = heading
    end

    attr_reader :heading

    def empty?
      false
    end

    include SectionsNavigation
  end
end
