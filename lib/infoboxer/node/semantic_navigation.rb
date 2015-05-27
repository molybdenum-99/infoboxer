# encoding: utf-8
module Infoboxer
  module SemanticNavigation
    def wikilinks
      lookup(Wikilink, namespace: '')
    end

    def external_links
      lookup(ExternalLink)
    end

    def images
      lookup(Image)
    end

    def templates
      lookup(Template)
    end
  end
end
