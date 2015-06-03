# encoding: utf-8
module Infoboxer
  module ContextualNavigation
    def infoboxes
      ensure_context.lookup(:infoboxes, self)
    end

    def categories
      ensure_context.lookup(:categories, self)
    end

    private

    def ensure_context
      ensure_page.client.context or fail("No domain-related context found")
    end

    def ensure_page
      (is_a?(Page) ? self : lookup_parents(Page).first) or
        fail("Node is not inside Page, maybe parsed from text?")
    end
  end
end
