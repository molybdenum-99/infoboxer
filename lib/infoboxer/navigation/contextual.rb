# encoding: utf-8
module Infoboxer
  module ContextualNavigation
    def categories
      lookup(Wikilink, namespace: /^#{ensure_traits.category_prefix.join('|')}$/)
    end

    private

    def ensure_traits
      ensure_page.traits or fail("No site traits found")
    end

    def ensure_page
      (is_a?(Page) ? self : lookup_parents(Page).first) or
        fail("Node is not inside Page, maybe parsed from text?")
    end
  end

  Node.send :include, ContextualNavigation
end
