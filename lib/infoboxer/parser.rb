# encoding: utf-8
require 'ostruct'
require_relative 'parser/context'

module Infoboxer
  class Parser
    class << self
      def inline(text)
        new(Context.new(text)).inline
      end

      def paragraphs(text)
        new(Context.new(text)).paragraphs
      end

      def document(text)
        Document.new(paragraphs(text))
      end

      def fragment(text)
        new(Context.new(text)).long_inline
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
