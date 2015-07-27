# encoding: utf-8
module Infoboxer
  module NavigationSugar
    def wikilinks(namespace = '')
      lookup(Wikilink, namespace: namespace)
    end

    def headings(level = nil)
      lookup(Heading, level: level)
    end

    def paragraphs(*args, &block)
      lookup(BaseParagraph, *args, &block)
    end

    def external_links(*args, &block)
      lookup(ExternalLink, *args, &block)
    end

    def images(*args, &block)
      lookup(Image, *args, &block)
    end

    def templates(*args, &block)
      lookup(Template, *args, &block)
    end

    def tables(*args, &block)
      lookup(Table, *args, &block)
    end

    def lists(*args, &block)
      lookup(List, *args, &block)
    end

    def bold?
      has_parent?(Bold)
    end

    def italic?
      has_parent?(Italic)
    end

    def heading?(level = nil)
      has_parent?(Heading, level: level)
    end

    def infoboxes(*args, &block)
      lookup(Template, :infobox?, *args, &block)
    end

    # As users accustomed to have only one infobox on a page
    alias_method :infobox, :infoboxes
  end

  Tree::Node.send :include, NavigationSugar
end
