# encoding: utf-8
module Infoboxer
  class Nodes < Array
    [:select, :reject, :sort_by, :flatten, :compact].each do |sym|
      define_method(sym){|*args, &block|
        Nodes[*super(*args, &block)]
      }
    end

    def lookup(*args, &block)
      Nodes[*map{|c| c.lookup(*args, &block)}.flatten]
    end

    def lookup_child(*args, &block)
      map{|c| c.lookup_child(*args, &block)}.flatten
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
