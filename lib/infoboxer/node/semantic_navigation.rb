# encoding: utf-8
module Infoboxer
  module SemanticNavigation
    def wikilinks
      lookup(Wikilink)
    end

    def external_links
      lookup(ExternalLink)
    end

    def images
      lookup(Image)
    end
  end
end
