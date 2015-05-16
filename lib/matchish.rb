# encoding: utf-8
module Matchish
  class Pattern
    def initialize(pattern)
      @pattern = pattern
    end

    def guard(&block)
      @guard = block
      self
    end

    def ===(obj)
      @pattern === obj && (!@guard || @guard.call)
    end
  end
end

class Object
  def matchish
    Matchish::Pattern.new(self)
  end
end

class Regexp
  def guard(&block)
    matchish.guard(&block)
  end
end
