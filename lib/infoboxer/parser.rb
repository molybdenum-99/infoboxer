# encoding: utf-8
require 'ostruct'

module Infoboxer
  class Parser
    def initialize(context)
      @context = context
      @re = OpenStruct.new(make_regexps)
    end

    attr_reader :context

    def inline(until_pattern = nil)
      nodes = Nodes[]
      loop do
        chunk = @context.scan_until(re.inline_until_cache[until_pattern])
        nodes << chunk

        break if @context.matched?(until_pattern)

        nodes << inline_formatting(@context.matched) unless @context.eol?

        if @context.eof?
          break unless until_pattern
          @context.fail!("#{until_pattern} not found")
        end
        
        if @context.eol?
          nodes << "\n"
          @context.next!
        end
      end
      
      nodes
    end

    def short_inline(until_pattern = nil)
      nodes = Nodes[]
      loop do
        chunk = @context.scan_until(re.short_inline_until_cache[until_pattern])
        nodes << chunk

        break if @context.matched?(until_pattern) || @context.inline_eol?

        nodes << inline_formatting(@context.matched)
      end
      
      nodes
    end

    private
      def inline_formatting(match)
        case match
        when "'''''"
          BoldItalic.new(short_inline(/'''''/))
        when "'''"
          Bold.new(short_inline(/'''/))
        when "''"
          Italic.new(short_inline(/''/))
        when '[['.matchish.guard{ @context.check(re.file_prefix) }
          image
        when '[['
          wikilink
        when /\[(.+)/
          external_link($1)
        #when '{{'
          #template
        #when /<ref(.*)\/>/
          #reference($1, '')
        #when /<ref(.*)>/
          #reference($1)
        when '<'
          html || Text.new(match) # it was not HTML, just accidental <
        else
          match # FIXME: TEMP
        end
      end

      # http://en.wikipedia.org/wiki/Help:Link#Wikilinks
      # [[abc]]
      # [[a|b]]
      def wikilink
        link = @context.scan_continued_until(/\||\]\]/)
        caption = inline(/\]\]/) if @context.matched == '|'
        Wikilink.new(link, caption)
      end

      # http://en.wikipedia.org/wiki/Help:Link#External_links
      # [http://www.example.org]
      # [http://www.example.org link name]
      def external_link(protocol)
        link = @context.scan_continued_until(/\s+|\]/)
        caption = inline(/\]/) if @context.matched =~ /\s+/
        ExternalLink.new(protocol + link, caption)
      end

      def image
        @context.skip(re.file_prefix) or
          @context.fail!("Something went wrong: it's not image?")

        path = @context.scan_until(/\||\]\]/)
        attrs = if @context.matched == '|'
          image_attrs
        else
          {}
        end
        Image.new(path, attrs)
      end

      def image_attrs
        nodes = []

        loop do
          nodes << inline(/\||\]\]/)
          break if @context.matched == ']]'
        end

        nodes.map(&method(:image_attr)).
          inject(&:merge).
          reject{|k, v| v.nil? || v.empty?}
      end

      def image_attr(nodes)
        case (str = nodes.text)
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
          {caption: nodes}
        end
      end

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
            if q
              value = scan.scan_until(/#{q}/).sub(q, '')
            else
              value = scan.scan_until(/\s|$/)
            end
            params[name.to_sym] = value
          else
            params[name.to_sym] = name
          end
        end
        params
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
    
  end
end
