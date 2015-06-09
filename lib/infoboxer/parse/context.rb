# encoding: utf-8
module Infoboxer
  module Parse
    class Context
      attr_reader :lineno
      attr_reader :traits

      def initialize(text, traits = nil)
        @lines = text.
          gsub(/<!--.+?-->/m, ''). # FIXME: will also kill comments inside <nowiki> tag
          split(/[\r\n]/)
        @lineno = -1
        @traits = traits || MediaWiki::Traits.default
        @traits.re ||= make_regexps.freeze
        @scanner = StringScanner.new('')
        next!
      end

      def re
        @traits.re
      end

      # lines navigation
      def current
        @scanner ? @scanner.rest : ''
      end
      
      def next_lines
        @lines[(lineno+1)..-1]
      end

      def next!
        shift(+1)
      end

      def prev!
        shift(-1)
      end

      def eof?
        lineno >= @lines.count
      end

      # scanning
      def scan(re)
        @scanner.scan(re)
      end

      def check(re)
        @scanner.check(re)
      end

      def rest
        @scanner.rest
      end

      def skip(re)
        @scanner.skip(re)
      end

      def scan_until(re, leave_pattern = false)
        @scanner.scan_until(re).tap{|res|
          res.sub!(@scanner.matched, '') if res && !leave_pattern
        }
      end

      def matched
        @scanner && @scanner.matched
      end

      def rewind(count)
        @scanner.pos -= count
      end

      def scan_through_until(re, leave_pattern = false)
        res = ''
        chunk_end = /({{|\[\[|#{re})/
        
        loop do
          chunk = @scanner.scan_until(chunk_end)
          case @scanner.matched
          when '{{'
            res << chunk << scan_through_until(/}}/, true)
          when '[['
            res << chunk << scan_through_until(/\]\]/, true)
          when re
            res << chunk
            break
          when nil
            res << @scanner.rest << "\n"
            next!
            eof? && fail!("Unfinished scan: #{re} not found")
          end
        end
        
        if leave_pattern 
          res
        else
          res.sub(/#{re}\Z/, '')
        end
      end

      def scan_continued_until(re, leave_pattern = false)
        res = ''
        
        loop do
          chunk = @scanner.scan_until(re)
          case @scanner.matched
          when re
            res << chunk
            break
          when nil
            res << @scanner.rest << "\n"
            next!
            eof? && fail!("Unfinished scan: #{re} not found")
          end
        end
        
        if leave_pattern 
          res
        else
          res.sub(/#{re}\Z/, '')
        end
      end

      def fail!(text)
        fail(ParsingError, "#{text} at line #{@lineno}:\n\t#{current}")
      end

      private

      FORMATTING = /(
        '{2,5}        |     # bold, italic
        \[\[          |     # link
        {{            |     # template
        \[[a-z]+:\/\/ |     # external link
        <ref[^>]*>    |     # reference
        <                   # HTML tag
      )/x


      def make_regexps
        {
          file_prefix: /(#{traits.file_prefix.join('|')}):/,
          formatting: FORMATTING
        }
      end

      def shift(amount)
        @lineno += amount
        current = @lines[lineno]
        if current
          @scanner.string = current
        else
          @scanner = nil
        end
      end
    end

    class SimpleContext < Context
      def initialize(text, traits)
        @lines = [text.gsub(/<!--.+?-->/m, '')]
        @lineno = -1
        @traits = traits || MediaWiki::Traits.default
        @traits.re ||= make_regexps.freeze
        @scanner = StringScanner.new('')
        next!
      end
    end
  end
end
