# encoding: utf-8

module Infoboxer
  module Tree
    # List of nodes, which tries to be useful both as array, and as proxy
    # to its contents.
    #
    # Many of Infoboxer's methods (especially {Navigation}'s) return
    # `Nodes`, and in most cases you don't have to think about it. Same
    # approach can be seen in jQuery or Nokogiri. You just do things
    # like those:
    #
    # ```ruby
    # document.sections.                  # => Nodes returned,
    #   select{|section|                  #    you can treat them as array, but also...
    #     section.text.length > 1000      #
    #   }.                                #
    #   lookup(:Wikilink, text: /Chile/). #    ...use Infoboxer's methods
    #   follow.                           #    ...even to receive lists of other pages
    #   infoboxes.                        #    ...and use methods on them
    #   fetch('leader_name1').            #    ...including those which only some node types support
    #   map(&:text)                       #    ...and still have full-functioning Array
    # ```
    #
    class Nodes < Array
      # @!method select(&block)
      #    Just like Array#select, but returns Nodes

      # @!method reject(&block)
      #    Just like Array#reject, but returns Nodes

      # @!method sort_by(&block)
      #    Just like Array#sort_by, but returns Nodes

      # @!method flatten
      #    Just like Array#flatten, but returns Nodes

      # @!method compact
      #    Just like Array#compact, but returns Nodes

      # @!method grep(pattern)
      #    Just like Array#grep, but returns Nodes

      # @!method grep_v(pattern)
      #    Just like Array#grep_v, but returns Nodes

      # @!method -(other)
      #    Just like Array#-, but returns Nodes

      # @!method +(other)
      #    Just like Array#+, but returns Nodes

      %i[select reject sort_by flatten compact grep grep_v - +].each do |sym|
        define_method(sym) do |*args, &block|
          Nodes[*super(*args, &block)]
        end
      end

      # Just like Array#first, but returns Nodes, if provided with `n` of elements.
      def first(n = nil)
        if n.nil?
          super()
        else
          Nodes[*super(n)]
        end
      end

      # Just like Array#last, but returns Nodes, if provided with `n` of elements.
      def last(n = nil)
        if n.nil?
          super()
        else
          Nodes[*super(n)]
        end
      end

      # Just like Array#map, but returns Nodes, **if** all map results are Node
      def map
        res = super
        if res.all? { |n| n.is_a?(Node) || n.is_a?(Nodes) }
          Nodes[*res]
        else
          res
        end
      end

      # Just like Array#flat_map, but returns Nodes, **if** all map results are Node
      def flat_map
        res = super
        if res.all? { |n| n.is_a?(Node) || n.is_a?(Nodes) }
          Nodes[*res]
        else
          res
        end
      end

      # @!method prev_siblings
      #   Previous siblings (flat list) of all nodes inside.

      # @!method next_siblings
      #   Next siblings (flat list) of all nodes inside.

      # @!method siblings
      #   Siblings (flat list) of all nodes inside.

      # @!method fetch
      #   Fetches by name(s) variables for all templates inside.
      #
      #   See {Tree::Template#fetch} for explanation.

      %i[
        prev_siblings next_siblings siblings
        fetch
      ].each do |sym|
        define_method(sym) do |*args|
          make_nodes(map { |n| n.send(sym, *args) })
        end
      end

      # By list of variable names, fetches hashes of `{name => value}`
      # from all templates inside.
      #
      # See {Tree::Template#fetch_hash} for explanation.
      #
      # @return [Array<Hash>]
      def fetch_hashes(*args)
        map { |t| t.fetch_hash(*args) }
      end

      # Just join of all {Node#to_tree Node#to_tree} strings inside.
      def to_tree
        map(&:to_tree).join("\n")
      end

      def inspect
        '[' +
          case
          when count > MAX_CHILDREN
            self[0...MAX_CHILDREN].map(&:inspect).join(', ') +
            ", ...#{count - MAX_CHILDREN} more nodes"
          else
            map(&:inspect).join(', ')
          end + ']'
      end

      # Just join of all {Node#text Node#text}s inside.
      def text
        map(&:text).join
      end

      # Fetches pages by ALL wikilinks inside in ONE query to MediaWiki
      # API.
      #
      # **NB**: for now, if there's more then 50 wikilinks (limitation for
      # one request to API), Infoboxer **will not** try to do next page.
      # It will be fixed in next releases.
      #
      # @return [Nodes<MediaWiki::Page>] It is still `Nodes`, so you
      #   still can process them uniformely.
      def follow
        links = grep(Linkable)
        return Nodes[] if links.empty?
        page = first.lookup_parents(MediaWiki::Page).first or
          fail('Not in a page from real source')
        page.client or fail('MediaWiki client not set')
        pages = links.group_by(&:interwiki)
                     .flat_map { |iw, ls| page.client.get(*ls.map(&:link), interwiki: iw) }
        pages.count == 1 ? pages.first : Nodes[*pages]
      end

      # @private
      # Internal, used by {Parser}
      def <<(node)
        if node.is_a?(Array)
          node.each { |n| self << n }
        elsif last && last.can_merge?(node)
          last.merge!(node)
        else
          return if !node || node.empty?
          node = Text.new(node) if node.is_a?(String)
          super
        end
      end

      # @private
      # Internal, used by {Parser}
      def strip
        res = dup
        res.pop while res.last.is_a?(Text) && res.last.raw_text =~ /^\s*$/
        res.last.raw_text.sub!(/\s+$/, '') if res.last.is_a?(Text)
        res
      end

      # @private
      # Internal, used by {Parser}
      def flow_templates
        make_nodes(map { |n| n.is_a?(Paragraph) ? n.to_templates? : n })
      end

      private

      # @private For inspect shortening
      MAX_CHILDREN = 5

      def make_nodes(arr)
        Nodes[*arr.flatten]
      end
    end
  end
end
