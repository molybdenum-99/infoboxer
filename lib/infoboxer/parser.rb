# encoding: utf-8
require 'ostruct'
require_relative 'parser/context'
require 'procme'

module Infoboxer
  class Parser
    class ParsingError < RuntimeError
    end
    
    class << self
      def inline(text, traits = nil)
        new(context(text, traits)).inline
      end

      def paragraphs(text, traits = nil)
        new(context(text, traits)).paragraphs
      end

      def document(text, traits = nil)
        Document.new(paragraphs(text, traits))
      end

      def fragment(text, traits = nil)
        new(context(text, traits)).long_inline
      end

      private

      def context(text, traits)
        Context.new(text, coerce_traits(traits))
      end

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
    
    def initialize(context)
      @context = context
      @re = OpenStruct.new(make_regexps)
    end

    require_relative 'parser/inline'
    include Parser::Inline

    require_relative 'parser/paragraphs'
    include Parser::Paragraphs

    private

    require_relative 'parser/util'
    include Parser::Util
  end
end
