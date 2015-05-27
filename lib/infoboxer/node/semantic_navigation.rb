# encoding: utf-8
module Infoboxer
  module SemanticNavigation
    def wikilinks(namespace = '')
      if namespace
        lookup(Wikilink, namespace: namespace)
      else
        lookup(Wikilink)
      end
    end

    def paragraphs
      lookup(BaseParagraph)
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

    def tables
      lookup(Table)
    end
  end
end
