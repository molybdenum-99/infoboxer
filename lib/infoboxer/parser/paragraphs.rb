# encoding: utf-8
module Infoboxer
  class Parser
    module Paragraphs
      def paragraphs(until_pattern = nil)
        nodes = Nodes[]
        until @context.eof?
          nodes << paragraph(until_pattern)

          break if until_pattern && @context.matched?(until_pattern)

          @context.next!
        end
        nodes
      end

      private

        def paragraph(until_pattern)
          case @context.current
          when /^(?<level>={2,})\s*(?<text>.+?)\s*\k<level>$/
            heading(Regexp.last_match[:text], Regexp.last_match[:level])
          when /^\s*{\|/
            table
          when /^[\*\#:;]./
            list
          when /^-{4,}/
            HR.new
          when /^\s*$/
            # will, when merged, close previous paragraph or add spaces to <pre>
            EmptyParagraph.new(@context.current)
          when /^ /
            pre(until_pattern)
          else
            Paragraph.new(short_inline(until_pattern))
          end
        end

        def heading(text, level)
          Heading.new(Parser.inline(text), level.length)
        end

        # http://en.wikipedia.org/wiki/Help:List
        def list
          marker = @context.scan(/^([*\#:;]+)\s*/).strip
          List.construct(marker.chars.to_a, short_inline)
        end

        # FIXME: in fact, there's some formatting, that should work inside pre
        def pre(until_pattern)
          @context.skip(/^ /)
          str = if until_pattern
            @context.scan_until(/(#{until_pattern}|$)/)
          else
            @context.current
          end
          Pre.new(Nodes[Text.new(str)])
        end

      require_relative 'table'
      include Parser::Table
    end
  end
end
