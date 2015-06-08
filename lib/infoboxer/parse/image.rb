# encoding: utf-8
module Infoboxer
  module Parse
    # http://en.wikipedia.org/wiki/Wikipedia:Extended_image_syntax
    # [[File:Name|Type|Border|Location|Alignment|Size|link=Link|alt=Alt|Caption]]
    #
    # NB: ImageContentsParser parses WITHOUT surrounding [[, ]], e.g. tag contents!
    class ImageContentsParser
      include ProcMe
    
      def initialize(str, traits)
        @context = Context.new(str, traits)
      end

      def parse
        [parse_path, parse_attrs]
      end

      private

      attr_reader :scanner

      def parse_path
        @context.skip(@context.re[:file_prefix]) or
          @context.fail!("Something went wrong: it's not image?")

        @context.scan_until(/\||$/)
      end

      def parse_attrs
        strings = []

        loop do
          strings << @context.scan_through_until(/\||$/)
          break if @context.rest.empty?
        end
        
        strings.map{|s| parse_attr(s)}.
          inject(&:merge).reject{|k, v| v.nil? || v.empty?}
      end

      def parse_attr(str)
        case str
        when /^(thumb)(?:nail)?$/, /^(frame)(?:d)?$/
          {type: $1}
        when 'frameless'
          {type: str}
        when 'border'
          {border: str}
        when /^(baseline|middle|sub|super|text-top|text-bottom|top|bottom)$/
          {alignment: str}
        when /^(\d*)(?:x(\d+))?px$/
          {width: $1, height: $2}
        when /^link=(.*)$/i
          {link: $1}
        when /^alt=(.*)$/i
          {alt: $1}
        else # it's caption, and can have inline markup!
          {caption: Parse.inline(str, @context.traits)}
        end
      end
    end
  end
end
