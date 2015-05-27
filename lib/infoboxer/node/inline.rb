# encoding: utf-8
module Infoboxer
  class Italic < Compound
  end

  class Bold < Compound
  end

  class BoldItalic < Compound
  end

  class Link < Compound
    def initialize(link, label = nil)
      super(label || Nodes.new([Text.new(link)]), link: link)
    end

    def_readers :link
  end

  class Wikilink < Link
    def name
      @name || ensure_namespace.last
    end

    def namespace
      @namespace || ensure_namespace.first
    end

    private

    def ensure_namespace
      @name, @namespace = link.split(':', 2).reverse
      [@namespace ||= '', @name]
    end
  end

  class ExternalLink < Link
  end
end
