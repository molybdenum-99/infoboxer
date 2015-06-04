# encoding: utf-8
require 'procme'

module Infoboxer
  module Parse
    class ParsingError < Exception
    end

    class << self
      def paragraphs(text, context = nil)
        ParagraphsParser.new(text, coerce_context(context)).parse
      end

      alias_method :fragment, :paragraphs
      
      def inline(text, context = nil)
        InlineParser.new(text, coerce_context(context)).parse
      end

      def document(text, context = nil)
        Document.new(paragraphs(text, context))
      end

      private

      def coerce_context(context)
        case context
        when nil
          Context.default
        when Hash
          Context.new(external: context)
        when Context
          context
        else
          fail(ArgumentError, "Can't coerce context from #{contex.inspect}")
        end
      end
    end

    #def parse_inline
      #InlineParser.new(@lines.join("\n"), [], @context).parse
    #end

  end
end

require_relative 'parser/commons'
require_relative 'parser/context'
require_relative 'parser/paragraphs'
require_relative 'parser/inline'
