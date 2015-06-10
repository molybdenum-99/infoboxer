# encoding: utf-8
require 'ostruct'

module Infoboxer
  class Parser
    def initialize(context)
      @context = context
      @re = OpenStruct.new(make_regexps)
    end

    private
      
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
