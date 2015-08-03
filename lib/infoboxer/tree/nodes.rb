# encoding: utf-8
module Infoboxer
  module Tree
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

      def last(n = nil)
        if n.nil?
          super()
        else
          Nodes[*super(n)]
        end
      end

      def map
        res = super
        if res.all?{|n| n.is_a?(Node) || n.is_a?(Nodes)}
          Nodes[*res]
        else
          res
        end
      end

      [
        :prev_siblings, :next_siblings, :siblings,
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

      MAX_CHILDREN = 5
      
      def inspect
        '[' + 
          case
          when count > MAX_CHILDREN
            self[0...MAX_CHILDREN].map(&:inspect).join(', ') + ", ...#{count - MAX_CHILDREN} more nodes"
          else
            map(&:inspect).join(', ')
          end + ']'
      end

      def text
        map(&:text).join
      end

      def follow
        links = select{|n| n.respond_to?(:link)}.map(&:link)
        return Nodes[] if links.empty?
        page = first.lookup_parents(MediaWiki::Page).first or
          fail("Not in a page from real source")
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
end
