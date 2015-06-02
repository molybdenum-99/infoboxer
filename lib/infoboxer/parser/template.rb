# encoding: utf-8
module Infoboxer
  class Parser
    # http://en.wikipedia.org/wiki/Help:A_quick_guide_to_templates
    # Templates are complicated. They can have templates inside templates inside templates!
    #
    # NB: TemplateParser parses WITHOUT surrounding {{, }}, e.g. tag contents!
    class TemplateParser
      def initialize(str)
        @scanner = StringScanner.new(str)
      end

      def parse
        [parse_name, parse_variables]
      end

      private

      def parse_name
        @scanner.scan_until(/\||$/).sub('|', '')
      end

      def parse_variables
        strings = []
        level = 0
        link_level = 0
        @inside_value = false

        loop do
          s = scanner.scan_until(/\[\[|\]\]|{{|}}|\|/)
          case scanner.matched
          when '[['
            push_string(strings, s)
            link_level += 1
            @inside_value = true
          when ']]'
            push_string(strings, s)
            link_level -= 1
          when '{{'
            push_string(strings, s)
            level += 1
            @inside_value = true
          when '}}'
            push_string(strings, s)
            level -= 1
          when '|'
            if level > 0 || link_level > 0
              push_string(strings, s)
            else
              push_string(strings, s.sub('|', ''))
              @inside_value = false
            end
          when nil
            push_string(strings, scanner.rest)
            break
          end
        end
        strings.map(&:strip).reject(&:empty?).map{|s| parse_variable(s)}
      end

      def parse_variable(s)
        if s =~ /\A\s*([^ =]+)\s*=\s*(.*)\Z/m
          name, val = $1, $2
          {name.to_sym => parse_value(val)}
        else
          parse_value(s)
        end
      end

      def parse_value(s)
        # NB: using #try_parse instead of #parse:
        #  template variables CAN have inconsistent markup, like:
        #  {{name|var=''something}} - here '' is, in fact, CLOSING tag
        #  for italics, while open tag will be added on template evaluation
        #
        s = s.strip
        s.include?("\n") ?
          Parser.parse(s).children :
          InlineParser.try_parse(s)
      end

      def push_string(strings, str)
        if @inside_value
          strings.last << str
        else
          strings << str
        end
      end

      attr_reader :scanner
    end
  end
end
