# encoding: utf-8
require_relative 'table'

module Infoboxer
  module Parse
    class ParagraphsParser
      def initialize(context, until_re = nil)
        @context = context
        @until_re = until_re
        @nodes = Nodes.new
      end

      def parse
        until @context.eof?
          process_current

          break if @until_re && @context.matched =~ @until_re

          @context.next!
        end

        merge_nodes!
        flatten_templates!

        @nodes
      end

      private
        # Main paragraph type dispetcher -------------------------------
        def process_current
          case @context.current
          when /^(?<level>={2,})\s*(?<text>.+?)\s*\k<level>$/
            heading(Regexp.last_match[:text], Regexp.last_match[:level])
          when /^\s*{\|/
            table # it will parse lines, including current
          when /^[\*\#:;]./
            list
          when /^-{4,}/
            node(HR)
          when /^\s+$/.guard{@nodes.empty? || @nodes.last.closed? || !@nodes.last.is_a?(Pre)}
            # either space between paragraphs/lists, or empty line inside pre
            @nodes.empty? or @nodes.last.closed!
          when /^ /
            pre
          when '' # blank line = space between paragraphs/lists
            @nodes.empty? or @nodes.last.closed!
          else
            para
          end
        end

        # Paragraph-level nodes DSL ------------------------------------
        def para
          node(Paragraph, inline)
        end

        def heading(text, level)
          node(Heading, simple_inline(text), level.length)
        end

        # http://en.wikipedia.org/wiki/Help:List
        def list
          marker = @context.scan(/^([*\#:;]+)\s*/).strip
          @nodes << List.construct(marker.chars.to_a, inline)
        end

        # FIXME: in fact, there's some formatting, that should work inside pre
        def pre
          @context.skip(/^ /)
          str = @context.scan_until(/(#{@until_re || '@NOTEXISTINGDEFINITELY@'}|$)/)
          node(Pre, [Text.new(str)])
        end

        def table
          @nodes << TableParser.new(@context).parse
        end

        # Post-processing --------------------------------------------------
        def merge_nodes!
          return if @nodes.count < 2
          
          merged = [@nodes.first]

          @nodes[1..-1].each do |node|
            if merged.last.can_merge?(node)
              merged.last.merge!(node)
            else
              merged << node
            end
          end

          @nodes.replace(merged)
        end

        # If we have paragraph, which consists of templates only,
        # this paragraph should be REPLACED with templates.
        # This way, we get rid of situation, when first 3-5 paragraphs of
        # document is infoboxes, disambig marks and so on.
        #
        # FIXME: not sure, if this method is smart enough.
        def flatten_templates!
          flat = @nodes.map do |node|
            
            if node.is_a?(Paragraph) &&
              node.children.all?{|c| c.is_a?(Template) || c.matches?(Text, text: /^\s*$/)}

              node.children
            else
              node
            end
          end.flatten(1)

          @nodes.replace(flat)
        end

        # Basic internals --------------------------------------------------
        def inline
          if @until_re
            InlineParser.new(@context).parse_until(@until_re)
          else
            InlineParser.new(@context).parse
          end
        end

        def simple_inline(str)
          Parse.inline(str, @context.traits)
        end
        
        def node(klass, *arg)
          @nodes << klass.new(*arg)
        end
    end
  end
end
