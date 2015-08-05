# encoding: utf-8
module Infoboxer
  module Tree
    # Represents italic text.
    class Italic < Compound
    end

    # Represents bold text.
    class Bold < Compound
    end

    # Represents bold italic text (and no, it's not a comb of bold+italic,
    # from Wikipedia's markup point of view).
    class BoldItalic < Compound
    end

    # Base class for internal/external links,
    class Link < Compound
      def initialize(link, label = nil)
        super(label || Nodes.new([Text.new(link)]), link: link)
      end

      #@!attribute [r] link

      def_readers :link
    end

    # External link. Has other nodes as a contents, and, err, link (url).
    class ExternalLink < Link
    
      #@!attribute [r] url
      #  synonym for `#link`
      
      alias_method :url, :link
    end
  end
end

require_relative 'wikilink'
