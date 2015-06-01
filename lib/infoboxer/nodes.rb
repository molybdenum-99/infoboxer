# encoding: utf-8
module Infoboxer
  class Nodes < Array
    [:select, :reject, :sort_by, :flatten, :compact, :-].each do |sym|
      define_method(sym){|*args, &block|
        Nodes[*super(*args, &block)]
      }
    end

    def _lookup(selector)
      make_nodes map{|c| c._lookup(selector)}
    end

    def _lookup_children(selector)
      make_nodes map{|c| c._lookup_children(selector)}
    end

    def _lookup_parents(selector)
      make_nodes map{|c| c._lookup_parents(selector)}
    end

    def _lookup_siblings(selector)
      make_nodes map{|c| c._lookup_siblings(selector)}
    end

    def _find(selector)
      select{|n| n._matches?(selector)}
    end

    include Node::TreeNavigation

    MAX_CHILDREN = 3
    
    def inspect
      if count > MAX_CHILDREN
        '[' + self[0...MAX_CHILDREN].map(&:inspect).join(', ') + " ...#{self.count - MAX_CHILDREN} more]"
      else
        super
      end
    end

    private

    def make_nodes(arr)
      Nodes[*arr.flatten]
    end
  end
end
