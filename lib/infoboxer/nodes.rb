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
    
    def inspect(depth = 0)
      "[#{inspect_no_p(depth)}]"
    end

    def inspect_no_p(depth = 0)
      case
      when depth > 1
        "#{count} items"
      when count > MAX_CHILDREN
        self[0...MAX_CHILDREN].map{|c| c.inspect(depth+1)}.join(', ') + " ...#{count - MAX_CHILDREN} more"
      else
        map{|c| c.inspect(depth+1)}.join(', ')
      end
    end

    def text
      map(&:text).join
    end

    def <<(node)
      case node
      when String
        return if node.empty?
        if last.is_a?(Text)
          last.raw_text << node
        else
          super(Text.new(node))
        end
      when Text
        return if node.raw_text.empty?
        if last.is_a?(Text)
          last.raw_text << node.raw_text
        else
          super
        end
      when Array
        node.each{|n| self << n}
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
