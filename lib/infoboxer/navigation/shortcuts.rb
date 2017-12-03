module Infoboxer
  module Navigation
    # See {Shortcuts::Node Shortcuts::Node} for everything!
    module Shortcuts
      # `Shortcuts::Node` module provides some convenience methods for
      # most used lookups. It's not a rocket science (as you can see
      # from methods code), yet should make your code cleaner and
      # more readable.
      #
      # **NB**: as usual, {Tree::Nodes} class have synonyms for all of
      # those methods, so you can call them fearlessly on any results of
      # node lookup.
      #
      module Node
        # Returns all wikilinks inside current node.
        #
        # @param namespace from which namespace links do you want. It's
        #   `''` (main namespace only) by default, if you really want all
        #   wikilinks on the page, including categories, interwikies and
        #   stuff, use `wikilinks(nil)`
        # @return {Tree::Nodes}
        def wikilinks(namespace = '')
          lookup(Tree::Wikilink, namespace: namespace)
        end

        # Returns all headings inside current node.
        #
        # @param level headings level to return.
        # @return {Tree::Nodes}
        def headings(level = nil)
          lookup(Tree::Heading, level: level)
        end

        # Returns all paragraph-level nodes (list items, plain paragraphs,
        # headings and so on) inside current node.
        #
        # @param selectors node selectors, as described at {Lookup::Node}
        # @return {Tree::Nodes}
        def paragraphs(*selectors, &block)
          lookup(Tree::BaseParagraph, *selectors, &block)
        end

        # Returns all external links inside current node.
        #
        # @param selectors node selectors, as described at {Lookup::Node}
        # @return {Tree::Nodes}
        def external_links(*selectors, &block)
          lookup(Tree::ExternalLink, *selectors, &block)
        end

        # Returns all images (media) inside current node.
        #
        # @param selectors node selectors, as described at {Lookup::Node}
        # @return {Tree::Nodes}
        def images(*selectors, &block)
          lookup(Tree::Image, *selectors, &block)
        end

        # Returns all templates inside current node.
        #
        # @param selectors node selectors, as described at {Lookup::Node}
        # @return {Tree::Nodes}
        def templates(*selectors, &block)
          lookup(Tree::Template, *selectors, &block)
        end

        # Returns all tables inside current node.
        #
        # @param selectors node selectors, as described at {Lookup::Node}
        # @return {Tree::Nodes}
        def tables(*selectors, &block)
          lookup(Tree::Table, *selectors, &block)
        end

        # Returns all lists (ordered/unordered/definition) inside current node.
        #
        # @param selectors node selectors, as described at {Lookup::Node}
        # @return {Tree::Nodes}
        def lists(*selectors, &block)
          lookup(Tree::List, *selectors, &block)
        end

        # Returns true, if current node is **inside** bold.
        def bold?
          parent?(Tree::Bold)
        end

        # Returns true, if current node is **inside** italic.
        def italic?
          parent?(Tree::Italic)
        end

        # Returns true, if current node is **inside** heading.
        #
        # @param level optional concrete level to check
        def heading?(level = nil)
          parent?(Tree::Heading, level: level)
        end

        # Returns all infoboxes inside current node.
        #
        # Definition of what considered to be infobox depends on templates
        # set used when parsing the page.
        #
        # @param selectors node selectors, as described at {Lookup::Node}
        # @return {Tree::Nodes}
        def infoboxes(*selectors, &block)
          lookup(Tree::Template, :infobox?, *selectors, &block)
        end

        # Returns all wikilinks in "categories namespace".
        #
        # **NB**: depending on your MediaWiki settings, name of categories
        # namespace may vary. When you are using {MediaWiki#get}, Infoboxer
        # tries to handle this transparently (by examining used wiki for
        # category names), yet bad things may happen here.
        #
        # @return {Tree::Nodes}
        def categories
          lookup(Tree::Wikilink, namespace: /^#{ensure_traits.category_namespace.join('|')}$/)
        end

        # As users accustomed to have only one infobox on a page
        def infobox
          infoboxes.first
        end

        private

        def ensure_traits
          ensure_page.traits or fail('No site traits found')
        end

        def ensure_page
          (is_a?(MediaWiki::Page) ? self : lookup_parents(MediaWiki::Page).first) or
            fail('Node is not inside Page, maybe parsed from text?')
        end
      end

      # Companion module of {Shortcuts::Node Shortcuts::Node}, defining
      # all the same methods for {Tree::Nodes} so you can use them
      # uniformely on single node or list. See {Shortcuts::Node there} for
      # details.
      module Nodes
        # @!method wikilinks(namespace = '')
        # @!method headings(level = nil)
        # @!method paragraphs(*selectors, &block)
        # @!method external_links(*selectors, &block)
        # @!method images(*selectors, &block)
        # @!method templates(*selectors, &block)
        # @!method tables(*selectors, &block)
        # @!method lists(*selectors, &block)
        # @!method infoboxes(*selectors, &block)
        # @!method categories

        %i[wikilinks headings paragraphs external_links images
           templates tables lists infoboxes infobox categories]
          .each do |m|
            define_method(m) do |*args|
              make_nodes(map { |n| n.send(m, *args) })
            end
          end
      end
    end
  end
end
