# encoding: utf-8
module Infoboxer
  class Nodes < Array
    [:select, :reject, :sort_by, :flatten, :compact, :-].each do |sym|
      define_method(sym){|*args, &block|
        Nodes[*super(*args, &block)]
      }
    end

    def first(n = nil)
      if n.nil?
        super()
      else
        Nodes[*super(n)]
      end
    end

    [
      :prev_siblings, :next_siblings, :siblings,
      :sections, :in_sections,
      :templates, :tables, :lists, :wikilinks, :images, :paragraphs, :external_links,
      :infoboxes, :infobox,
      :fetch
    ].each do |sym|
      define_method(sym){|*args|
        make_nodes map{|n| n.send(sym, *args)}
      }
    end

    def fetch_hashes(*args)
      map{|t| t.fetch_hash(*args)}
    end

    def to_tree
      map(&:to_tree).join("\n")
    end

    def _find(selector)
      select{|n| n._matches?(selector)}
    end

    def find(*args, &block)
      _find(Node::Selector.new(*args, &block))
    end

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

    def follow
      links = select{|n| n.respond_to?(:link)}.map(&:link)
      return Nodes[] if links.empty?
      page = first.lookup_parents(Page).first or fail("Not in a page from real source")
      page.client or fail("MediaWiki client not set")
      page.client.get(*links)
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
      #make_nodes(map{|n| n.is_a?(Paragraph) && n.templates_only? ? n.templates : n})
      make_nodes map{|n| n.is_a?(Paragraph) ? n.to_templates? : n}
    end

    private

    def make_nodes(arr)
      Nodes[*arr.flatten]
    end
  end
end
