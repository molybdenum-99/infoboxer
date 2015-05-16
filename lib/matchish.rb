# encoding: utf-8
module Matchish
  class << self
    attr_accessor :last_match
  end
  
  class Pattern
    def initialize(pattern)
      @pattern = pattern
    end

    def guard(&block)
      @guard = block
      self
    end

    def ===(obj)
      (@pattern === obj && (!@guard || @guard.call)).tap{|res|
        Matchish.last_match = Regexp.last_match
      }
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
