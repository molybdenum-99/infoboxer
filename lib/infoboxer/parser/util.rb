# encoding: utf-8

module Infoboxer
  class Parser
    module Util
      attr_reader :re

      FORMATTING = %r((
        '''''|'''|''  |     # bold, italic, bold italic
        \[\[          |     # link
        {{            |     # template
        \[[a-z]+://   |     # external link
        <nowiki[^>]*> |     # nowiki
        <ref[^>]*>    |     # reference
        <math>        |     # math
        <                   # HTML tag
      ))x

      INLINE_EOL = %r[(?=   # if we have ahead... (not scanned, just checked
        </ref>        |     # <ref> closed
        }}
      )]x

      INLINE_EOL_BRACK = %r[(?=   # if we have ahead... (not scanned, just checked
        </ref>        |     # <ref> closed
        }}            |     # or template closed
        (?<!\])\](?!\])     # or ext.link closed,
                            # the madness with look-ahead/behind means
                            # "match single bracket but not double"
      )]x

      # FIXME: ok, NOW it's officially ridiculous
      INLINE_EOL_BRACK2 = %r[(?=   # if we have ahead... (not scanned, just checked
        </ref>        |     # <ref> closed
        }}            |     # or template closed
        \]\]                # or int.link closed
      )]x

      def make_regexps
        {
          file_namespace: /(#{@context.traits.file_namespace.join('|')}):/,
          formatting: FORMATTING,
          inline_until_cache: Hash.new { |h, r|
            h[r] = Regexp.union(*[r, FORMATTING, /$/].compact.uniq)
          },
          short_inline_until_cache: Hash.new { |h, r|
            h[r] = Regexp.union(*[r, INLINE_EOL, FORMATTING, /$/].compact.uniq)
          },
          short_inline_until_cache_brackets: Hash.new { |h, r|
            h[r] = Regexp.union(*[r, INLINE_EOL_BRACK, FORMATTING, /$/].compact.uniq)
          },
          short_inline_until_cache_brackets2: Hash.new { |h, r|
            h[r] = Regexp.union(*[r, INLINE_EOL_BRACK2, FORMATTING, /$/].compact.uniq)
          }
        }
      end

      def parse_params(str)
        return {} unless str

        scan = StringScanner.new(str)
        params = {}
        loop do
          scan.skip(/\s*/)
          name = scan.scan(/[^ \t=]+/) or break
          scan.skip(/\s*/)
          if scan.peek(1) == '='
            scan.skip(/=\s*/)
            q = scan.scan(/['"]/)
            value = q ? scan.scan_until(/#{q}|$/).sub(q, '') : scan.scan_until(/\s|$/)
            params[name.to_sym] = value
          else
            params[name.to_sym] = name
          end
        end
        params
      end

      def guarded_loop
        loop do
          pos_before = @context.lineno, @context.colno
          yield
          pos_after = @context.lineno, @context.colno
          pos_after == pos_before and
            @context.fail!("Infinite loop on position #{pos_after.last}")
        end
      end
    end
  end
end
