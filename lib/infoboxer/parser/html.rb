# encoding: utf-8
module Infoboxer
  class Parser
    module HTML
      def html
        case
        when @context.check(/\/[a-z]+>/)
          html_closing_tag
        when @context.check(/br\s*>/)
          html_br
        when @context.check(%r{[a-z]+[^/>]*/>})
          html_auto_closing_tag
        when @context.check(/[a-z]+[^>\/]+>/)
          html_opening_tag
        else
          # not an HTML tag at all!
          nil
        end
      end

      def html_closing_tag
        @context.skip(/\//)
        tag = @context.scan(/[a-z]+/)
        @context.skip(/>/)
        HTMLClosingTag.new(tag)
      end

      def html_br
        @context.skip(/br\s*>/)
        HTMLTag.new('br', {})
      end

      def html_auto_closing_tag
        tag = @context.scan(/[a-z]+/)
        attrs = @context.scan(%r{[^/>]*})
        @context.skip(%r{/>})
        HTMLTag.new(tag, parse_params(attrs))
      end

      def html_opening_tag
        tag = @context.scan(/[a-z]+/)
        attrs = @context.scan(/[^>]+/)
        @context.skip(/>/)
        contents = short_inline(/<\/#{tag}>/)
        if @context.matched =~ /<\/#{tag}>/
          HTMLTag.new(tag, parse_params(attrs), contents)
        else
          [
            HTMLOpeningTag.new(tag, parse_params(attrs)),
            *contents
          ]
        end
      end
    end
  end
end
