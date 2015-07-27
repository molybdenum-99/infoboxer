# encoding: utf-8
module Infoboxer
  module Tree
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

    class ExternalLink < Link
    end
  end
end

require_relative 'wikilink'
