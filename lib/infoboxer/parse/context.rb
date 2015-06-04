# encoding: utf-8
module Infoboxer
  module Parse
    class Context
      DEFAULT_OPTIONS = {
        next_lines: [],
        traits: MediaWiki::Traits.new
      }
      def self.default
        new
      end
      
      def initialize(options = {})
        @options = DEFAULT_OPTIONS.merge(options)
        @file_prefix = make_file_prefix
      end

      attr_reader :file_prefix

      def merge(opts)
        Context.new(@options.merge(opts))
      end

      def next_lines
        @options[:next_lines]
      end

      def expand(tmpl)
        traits.expand(tmpl)
      end

      private

      def traits
        @options[:traits]
      end

      def make_file_prefix
        '(' + traits.file_prefix.join('|') + ')'
      end
    end
  end
end
