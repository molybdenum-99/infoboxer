# encoding: utf-8
require 'ostruct'

module Infoboxer
  class Parser
    def initialize(context)
      @context = context
      @re = OpenStruct.new(make_regexps)
    end

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
        #when /^(?<level>={2,})\s*(?<text>.+?)\s*\k<level>$/
          #heading(Regexp.last_match[:text], Regexp.last_match[:level])
        #when /^\s*{\|/
          #table # it will parse lines, including current
        #when /^[\*\#:;]./
          #list
        #when /^-{4,}/
          #node(HR)
        when /^\s*$/
          # will, when merged, close previous paragraph or add spaces to <pre>
          EmptyParagraph.new(@context.current)
        #when /^ /
          #pre
        else
          Paragraph.new(short_inline(until_pattern))
        end
      end
      
      attr_reader :re

      FORMATTING = /(
        '{2,5}        |     # bold, italic
        \[\[          |     # link
        {{            |     # template
        \[[a-z]+:\/\/ |     # external link
        <ref[^>]*>    |     # reference
        <                   # HTML tag
      )/x

      INLINE_EOL = %r[(?=   # if we have ahead... (not scanned, just checked
        </ref>        |     # <ref> closed
        }}                  # or template closed
      )]x


      def make_regexps
        {
          file_prefix: /(#{@context.traits.file_prefix.join('|')}):/,
          formatting: FORMATTING,
          inline_until_cache: Hash.new{|h, r|
            h[r] = Regexp.union(*[r, FORMATTING, /$/].compact.uniq)
          },
          short_inline_until_cache: Hash.new{|h, r|
            h[r] = Regexp.union(*[r, INLINE_EOL, FORMATTING, /$/].compact.uniq)
          }
        }
      end
    require_relative 'parser/inline'
    require_relative 'parser/util'
    include Parser::Inline
    include Parser::Util
  end
end
