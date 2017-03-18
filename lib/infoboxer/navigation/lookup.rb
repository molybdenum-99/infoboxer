# encoding: utf-8
require_relative 'selector'

module Infoboxer
  module Navigation
    # See {Lookup::Node Lookup::Node} for everything!
    module Lookup
      # `Lookup::Node` module provides methods for navigating through
      # page tree in XPath-like manner.
      #
      # What you need to know about it:
      #
      # ## Selectors
      #
      # Each `lookup_*` method (and others similar) receive
      # _list of selectors_. Examples of acceptable selectors:
      #
      # ```ruby
      # # 1. Node class:
      # document.lookup(Bold) # all Bolds
      #
      # # 2. Class symbol
      # document.lookup(:Bold)
      # # same as above, useful if you don't want to include Infoboxer::Tree
      # # in all of your code or write things like lookup(Infoboxer::Tree::Bold)
      #
      # # 3. Getter/pattern:
      # document.lookup(text: /something/)
      # # finds all nodes where result of getter matches pattern
      #
      # # Checks against patterns are performed with `===`, so you can
      # # use regexps to find by text, or ranges to find by number, like
      # document.lookup(:Heading, level: (3..4))
      #
      # # Nodes where method is not defined are ignored, so you can
      # # rewrite above example as just
      # document.lookup(level: 3..4)
      # # ...and receive meaningful result without any NoMethodError
      #
      # # 4. Check symbol
      # document.lookup(:bold?)
      # # finds all nodes for which `:bold?` is defined and returns
      # # truthy value;
      #
      # # 5. Code block
      # document.lookup{|node| node.params.has_key?(:class)}
      # ```
      #
      # You also can use any of those method without **any** selector,
      # thus receiving ALL parents, ALL children, ALL siblings and so on.
      #
      # ## Chainable navigation
      #
      # Each `lookup_*` method returns an instance of {Tree::Nodes} class,
      # which behaves like an Array, but also defines similar set of
      # `lookup_*` methods, so, you can brainlessly do the things like
      #
      # ```ruby
      # document.
      #   lookup(:Paragraph){|p| p.text.length > 100}.
      #   lookup(:Wikilink, text: /^List of/).
      #   select(&:bold?)
      # ```
      #
      # ## Underscored methods
      #
      # For all methods of this module you can notice "underscored" version
      # (`lookup_children` vs `_lookup_children` and so on). Basically,
      # underscored versions accept instance of {Lookup::Selector}, which
      # is already preprocessed version of all selectors. It is kinda
      # internal thing, though can be useful if you store selectors in
      # variables -- it is easier to have and use just one instance of
      # Selector, than list of arguments and blocks.
      #
      module Node
        # @!method matches?(*selectors, &block)
        #   Checks if current node matches selectors.

        # @!method lookup(*selectors, &block)
        #   Selects matching nodes from entire subtree inside current node.

        # @!method lookup_children(*selectors, &block)
        #   Selects nodes only from this node's direct children.

        # @!method lookup_parents(*selectors, &block)
        #   Selects matching nodes of this node's parents chain, up to
        #   entire {Tree::Document Document}.

        # @!method lookup_siblings(*selectors, &block)
        #   Selects matching nodes from current node's siblings.

        # @!method lookup_next_siblings(*selectors, &block)
        #   Selects matching nodes from current node's siblings, which
        #   are below current node in parents children list.

        # @!method lookup_prev_siblings(*selectors, &block)
        #   Selects matching nodes from current node's siblings, which
        #   are above current node in parents children list.

        # Underscored version of {#matches?}
        def _matches?(selector)
          selector.matches?(self)
        end

        # Underscored version of {#lookup}
        def _lookup(selector)
          Tree::Nodes[_matches?(selector) ? self : nil, *children._lookup(selector)]
            .flatten.compact
        end

        # Underscored version of {#lookup_children}
        def _lookup_children(selector)
          @children._find(selector)
        end

        # Underscored version of {#lookup_parents}
        def _lookup_parents(selector)
          case
          when !parent
            Tree::Nodes[]
          when parent._matches?(selector)
            Tree::Nodes[parent, *parent._lookup_parents(selector)]
          else
            parent._lookup_parents(selector)
          end
        end

        # Underscored version of {#lookup_siblings}
        def _lookup_siblings(selector)
          siblings._find(selector)
        end

        # Underscored version of {#lookup_prev_siblings}
        def _lookup_prev_siblings(selector)
          prev_siblings._find(selector)
        end

        # Underscored version of {#lookup_next_siblings}
        def _lookup_next_siblings(selector)
          next_siblings._find(selector)
        end

        %i[
          matches?
          lookup lookup_children lookup_parents
          lookup_siblings
          lookup_next_siblings lookup_prev_siblings
        ]
          .map { |sym| [sym, :"_#{sym}"] }
          .each do |sym, underscored|

          define_method(sym) do |*args, &block|
            send(underscored, Selector.new(*args, &block))
          end
        end

        # Checks if node has any parent matching selectors.
        def parent?(*selectors, &block)
          !lookup_parents(*selectors, &block).empty?
        end
      end

      # This module provides implementations for all `lookup_*` methods
      # of {Lookup::Node} for be used on nodes list. Note, that all
      # those methods return _flat_ list of results (so, if you have
      # found several nodes, and then look for their siblings, you should
      # not expect array of arrays -- just one array of nodes).
      #
      # See {Lookup::Node} for detailed lookups and selectors explanation.
      module Nodes
        # @!method lookup(*selectors, &block)
        # @!method lookup_children(*selectors, &block)
        # @!method lookup_parents(*selectors, &block)
        # @!method lookup_siblings(*selectors, &block)
        # @!method lookup_next_siblings(*selectors, &block)
        # @!method lookup_prev_siblings(*selectors, &block)

        # @!method _lookup(selector)
        # @!method _lookup_children(selector)
        # @!method _lookup_parents(selector)
        # @!method _lookup_siblings(selector)
        # @!method _lookup_next_siblings(selector)
        # @!method _lookup_prev_siblings(selector)

        # Underscored version of {#find}.
        def _find(selector)
          select { |n| n._matches?(selector) }
        end

        # Selects nodes of current list (and only it, no children checks),
        # which are matching selectors.
        def find(*selectors, &block)
          _find(Selector.new(*selectors, &block))
        end

        [
          :_lookup, :_lookup_children, :_lookup_parents,
          :_lookup_siblings, :_lookup_prev_siblings, :_lookup_next_siblings
        ].each do |sym|
          define_method(sym) do |*args|
            make_nodes map { |n| n.send(sym, *args) }
          end
        end

        # not delegate, but redefine: Selector should be constructed only once
        [
          :lookup, :lookup_children, :lookup_parents,
          :lookup_siblings,
          :lookup_next_siblings, :lookup_prev_siblings
        ].map { |sym| [sym, :"_#{sym}"] }.each do |sym, underscored|

          define_method(sym) do |*args, &block|
            send(underscored, Selector.new(*args, &block))
          end
        end
      end
    end
  end
end
