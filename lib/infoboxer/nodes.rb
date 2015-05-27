# encoding: utf-8
module Infoboxer
  class Nodes < Array
    [:select, :reject, :sort_by, :flatten, :compact].each do |sym|
      define_method(sym){|*args, &block|
        Nodes[*super(*args, &block)]
      }
    end

    def lookup(*args, &block)
      _lookup(Node::Selector.new(*args, &block))
    end

    def lookup_child(*args, &block)
      _lookup_child(Node::Selector.new(*args, &block))
    end

    def _lookup(selector)
      Nodes[*map{|c| c._lookup(selector)}.flatten]
    end

    def _lookup_child(selector)
      map{|c| c._lookup_child(selector)}.flatten
    end

    MAX_CHILDREN = 3
    
    def inspect
      if count > MAX_CHILDREN
        '[' + self[0...MAX_CHILDREN].map(&:inspect).join(', ') + " ...#{self.count - MAX_CHILDREN} more]"
      else
        super
      end
    end
  end
end
