# encoding: utf-8
require_relative 'node_selector'

module Infoboxer
  module NodeLookup
    def _matches?(selector)
      selector.matches?(self)
    end

    def _lookup(selector)
      Nodes[_matches?(selector) ? self : nil, *children._lookup(selector)].
        flatten.compact
    end

    def _lookup_children(selector)
      @children._find(selector)
    end

    def _lookup_parents(selector)
      case
      when !parent
        Nodes[]
      when parent._matches?(selector)
        Nodes[parent, *parent._lookup_parents(selector)]
      else
        parent._lookup_parents(selector)
      end
    end

    def _lookup_siblings(selector)
      siblings._find(selector)
    end

    def _lookup_prev_siblings(selector)
      prev_siblings._find(selector)
    end

    def _lookup_next_siblings(selector)
      next_siblings._find(selector)
    end
    
    [:matches?,
      :lookup, :lookup_children, :lookup_parents,
      :lookup_siblings,
      :lookup_next_siblings, :lookup_prev_siblings
    ].map{|sym| [sym, :"_#{sym}"]}.each do |sym, underscored|

      define_method(sym){|*args, &block|
        send(underscored, Selector.new(*args, &block))
      }
    end

    def has_parent?(*args, &block)
      !lookup_parents(*args, &block).empty?
    end
  end

  module NodesLookup
    [
      :_lookup, :_lookup_children, :_lookup_parents,
      :_lookup_siblings, :_lookup_prev_siblings, :_lookup_next_siblings
    ].each do |sym|
      define_method(sym){|*args|
        make_nodes map{|n| n.send(sym, *args)}
      }
    end

    # not delegate, but redefine: Selector should be constructed only once
    [
      :lookup, :lookup_children, :lookup_parents,
      :lookup_siblings,
      :lookup_next_siblings, :lookup_prev_siblings
    ].map{|sym| [sym, :"_#{sym}"]}.each do |sym, underscored|

      define_method(sym){|*args, &block|
        send(underscored, NodeLookup::Selector.new(*args, &block))
      }
    end
  end

  Node.send(:include, NodeLookup)
  Nodes.send(:include, NodesLookup)
end
