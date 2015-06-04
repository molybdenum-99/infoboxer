# encoding: utf-8
module Infoboxer
  module Parse
    class Context
      DEFAULT_OPTIONS = {
        file_prefix: 'File',
        next_lines: []
      }
      def self.default
        new
      end
      
      def initialize(options = {})
        @options = DEFAULT_OPTIONS.merge(options)
      end

      def merge(opts)
        Context.new(@options.merge(opts))
      end

      def file_prefix
        @options[:external] && @options[:external][:file_prefix] ||
          @options[:file_prefix]
      end

      def next_lines
        @options[:next_lines]
      end

      def expand(tmpl)
        @options[:external] ? @options[:external].expand(tmpl) : tmpl
      end
    end
  end
end
