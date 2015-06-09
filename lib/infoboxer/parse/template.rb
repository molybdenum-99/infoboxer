# encoding: utf-8
module Infoboxer
  module Parse
    # http://en.wikipedia.org/wiki/Help:A_quick_guide_to_templates
    # Templates are complicated. They can have templates inside templates inside templates!
    #
    # NB: TemplateContentsParser parses WITHOUT surrounding {{, }}, e.g. tag contents!
    class TemplateContentsParser
      def initialize(context)
        @context = context
      end

      def parse
        name = @context.scan_continued_until(/\||}}/) or
          @context.fail!("Template name not found")
        name.strip!
        vars = @context.matched == '}}' ? {} : variables
        [name, vars]
      end

      private

      def variables
        num = 1
        res = {}
        
        loop do
          if @context.check(/\s*([^ =]+)\s*=\s*/)
            name = @context.scan(/\s*([^ =]+)/).strip.to_sym
            @context.skip(/\s*=\s*/)
          else
            name = num
          end

          value = InlineParser.new(@context).parse_until(/\||}}/, allow_paragraphs: true)
          res[name] = value

          break if @context.matched == '}}'
          @context.eof? and @context.fail!("Unexpected break of template variables: #{res}")

          num += 1
        end
        res
      end
    end
  end
end
