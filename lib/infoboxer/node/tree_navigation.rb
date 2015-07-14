# encoding: utf-8
module Infoboxer
  class Node
    module TreeNavigation
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

      def _matches?(selector)
        selector.matches?(self)
      end

      def _lookup(selector)
        _matches?(selector) ? self : nil
      end

      def has_parent?(*args, &block)
        !lookup_parents(*args, &block).empty?
      end
      
      [:matches?,
        :lookup, :lookup_children, :lookup_parents,
        :lookup_siblings,
        #:lookup_next_siblings, :lookup_prev_siblings # TODO
        ].
        map{|sym| [sym, :"_#{sym}"]}.each do |sym, underscored|

        define_method(sym){|*args, &block|
          send(underscored, Selector.new(*args, &block))
        }
      end
    end
  end
end
