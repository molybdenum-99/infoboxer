# encoding: utf-8
module Infoboxer
  class Parser
    # http://en.wikipedia.org/wiki/Wikipedia:Extended_image_syntax
    # [[File:Name|Type|Border|Location|Alignment|Size|link=Link|alt=Alt|Caption]]
    #
    # NB: ImageParser parses WITHOUT surrounding [[, ]], e.g. tag contents!
    class ImageParser
      include ProcMe
    
      def initialize(str, context=nil)
        @context = context
        @scanner = StringScanner.new(str)
      end

      def parse
        [parse_path, parse_attrs]
      end

      private

      attr_reader :scanner

      def parse_path
        scanner.skip(/(File|Image):/) or
          fail("Something went wrong: it's not image: #{str}?")

        scanner.scan_until(/\||$/).sub('|', '')
      end

      def parse_attrs
        @inside_caption = false
        strings = []
        loop do
          s = scanner.scan_until(/\||\[\[|{{/)
          case scanner.matched
          when '[['
            # start of link inside caption - it CAN contain | symbol
            link_contents = scanner.scan_until(/\]\]/) or
              fail("Something went wrong: unbalanced parens inside image #{scanner.rest}")

            push_string(strings, s + link_contents)
            @inside_caption = true
          when '{{'
            # start of template inside caption - it CAN contain | symbol
            template_contents = scanner.scan_until(/\}\}/) or
              fail("Something went wrong: unbalanced parens inside image #{scanner.rest}")

            push_string(strings, s + template_contents)
            @inside_caption = true
          when '|'
            push_string(strings, s.sub('|', ''))
            @inside_caption = false
          when nil
            push_string(strings, scanner.rest)
            break
          end
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
          {caption: InlineParser.new(str, [], @context).parse}
        end
      end

      def push_string(strings, str)
        if @inside_caption
          strings.last << str
        else
          strings << str
        end
      end
    end
  end
end
