# encoding: utf-8

require 'ostruct'
require 'logger'

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

      def paragraph(text, traits = nil)
        paragraphs(text, traits).first
      end

      def document(text, traits = nil)
        Tree::Document.new(paragraphs(text, traits))
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

    include Tree

    def initialize(context)
      @context = context
      @re = OpenStruct.new(make_regexps)
      @logger = Logger.new(STDOUT).tap { |l| l.level = Logger::FATAL }
    end

    require_relative 'parser/inline'
    include Parser::Inline

    require_relative 'parser/paragraphs'
    include Parser::Paragraphs

    private

    require_relative 'parser/util'
    include Parser::Util

    def log(msg)
      @logger.info "#{msg} | #{@context.lineno}:#{@context.colno}: #{@context.current}"
    end
  end
end

require_relative 'parser/context'
