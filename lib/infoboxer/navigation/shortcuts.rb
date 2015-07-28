# encoding: utf-8
module Infoboxer
  module Navigation
    module Shortcuts
      module Node
        def wikilinks(namespace = '')
          lookup(Tree::Wikilink, namespace: namespace)
        end

        def headings(level = nil)
          lookup(Tree::Heading, level: level)
        end

        def paragraphs(*args, &block)
          lookup(Tree::BaseParagraph, *args, &block)
        end

        def external_links(*args, &block)
          lookup(Tree::ExternalLink, *args, &block)
        end

        def images(*args, &block)
          lookup(Tree::Image, *args, &block)
        end

        def templates(*args, &block)
          lookup(Tree::Template, *args, &block)
        end

        def tables(*args, &block)
          lookup(Tree::Table, *args, &block)
        end

        def lists(*args, &block)
          lookup(Tree::List, *args, &block)
        end

        def bold?
          has_parent?(Tree::Bold)
        end

        def italic?
          has_parent?(Tree::Italic)
        end

        def heading?(level = nil)
          has_parent?(Tree::Heading, level: level)
        end

        def infoboxes(*args, &block)
          lookup(Tree::Template, :infobox?, *args, &block)
        end

        def categories
          lookup(Tree::Wikilink, namespace: /^#{ensure_traits.category_prefix.join('|')}$/)
        end

        # As users accustomed to have only one infobox on a page
        alias_method :infobox, :infoboxes

        private

        def ensure_traits
          ensure_page.traits or fail("No site traits found")
        end

        def ensure_page
          (is_a?(Page) ? self : lookup_parents(Page).first) or
            fail("Node is not inside Page, maybe parsed from text?")
        end
      end

      module Nodes
        [:wikilinks, :headings, :paragraphs, :external_links, :images,
         :templates, :tables, :lists, :infoboxes, :infobox, :categories].
          each do |m|
            define_method(m){|*args|
              make_nodes map{|n| n.send(m, *args)}
            }
          end
      end
    end
  end
end
