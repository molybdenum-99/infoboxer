# encoding: utf-8
require 'procme'

module Infoboxer
  module Parse
    class ParsingError < Exception
    end

    class << self
      def paragraphs(text, traits = nil)
        ParagraphsParser.new(Context.new(text, coerce_traits(traits))).parse
      end

      def inline(text, traits = nil)
        #InlineParser.new(SimpleContext.new(text, coerce_traits(traits))).parse
        InlineParser.new(Context.new(text, coerce_traits(traits))).parse
      end

      def inline_or_paragraphs(text, traits = nil)
        text.include?("\n") ? paragraphs(text, traits) : inline(text, traits)
      end

      alias_method :fragment, :inline_or_paragraphs

      def document(text, traits = nil)
        Document.new(paragraphs(text, traits))
      end

      private

      def coerce_traits(traits)
        case traits
        when nil
          MediaWiki::Traits.default
        when Hash
          MediaWiki::Traits.new(traits)
        when MediaWiki::Traits
          traits
        else
          fail(ArgumentError, "Can't coerce site traits from #{traits.inspect}")
        end
      end
    end
  end
end

require_relative 'parse/commons'
require_relative 'parse/context'
require_relative 'parse/paragraphs'
require_relative 'parse/inline'
