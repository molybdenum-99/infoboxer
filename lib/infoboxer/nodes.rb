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

    def find(*args, &block)
      _find(Node::Selector.new(*args, &block))
    end

    include Node::TreeNavigation

    MAX_CHILDREN = 3
    
    def inspect(depth = 0)
      "[#{inspect_no_p(depth)}]"
    end

    def inspect_no_p(depth = 0)
      case
      when depth > 1
        "#{count} nodes"
      when count > MAX_CHILDREN
        self[0...MAX_CHILDREN].map{|c| c.inspect(depth+1)}.join(', ') + " ...#{count - MAX_CHILDREN} more nodes"
      else
        map{|c| c.inspect(depth+1)}.join(', ')
      end
    end

    def text
      map(&:text).join
    end

    def <<(node)
      if node.kind_of?(Array)
        node.each{|n| self << n}
      elsif last && last.can_merge?(node)
        last.merge!(node)
      else
        return if !node || node.empty?
        node = Text.new(node) if node.is_a?(String)
        super
      end
    end

    def strip
      res = dup
      res.pop while res.last.is_a?(Text) && res.last.raw_text =~ /^\s*$/
      res.last.raw_text.sub!(/\s+$/, '') if res.last.is_a?(Text)
      res
    end

    def flow_templates
      make_nodes(map{|n| n.is_a?(Paragraph) && n.templates_only? ? n.templates : n})
    end

    private

    def make_nodes(arr)
      Nodes[*arr.flatten]
    end
  end
end
