# encoding: utf-8
require_relative 'image'
require_relative 'template'

# http://www.mediawiki.org/wiki/Help:Formatting
module Infoboxer
  module Parse
    class InlineParser
      def initialize(context)
        @context = context

        @nodes = Nodes.new
      end

      def parse
        until @context.eof?
          str = @context.scan_until(@context.re[:formatting])
          text(str.to_s)

          if @context.matched.nil?
            text(@context.rest)
            break
          else
            process_formatting(@context.matched)
          end
        end
        @nodes.pop while @nodes.last.is_a?(Text) && @nodes.last.raw_text.strip.empty?
        @nodes.last.raw_text.strip! if @nodes.last.is_a?(Text)
        @nodes
      end

      def parse_until(re, options = {})
        start = @context.lineno
        until @context.eof?
          str = @context.scan_until(@context.re[:until_cache][re])
          text(str.to_s)

          break if @context.matched =~ re || options[:inline_eol] && inline_eol?

          process_formatting(@context.matched)
          if @context.current.empty?
            @context.next!
            if options[:allow_paragraphs]
              @nodes.concat(ParagraphsParser.new(@context, re).parse)
              break
            else
              text(' ')
            end
          end
          
          if @context.eof?
            if options[:inline_eol]
              break
            else
              @context.fail!("Unfinished formatting: #{re} not found (started on #{start})")
            end
          end
        end
        @nodes.pop while @nodes.last.is_a?(Text) && @nodes.last.raw_text.strip.empty?
        @nodes.last.raw_text.strip! if @nodes.last.is_a?(Text)
        @nodes
      end

      private

      def text(txt)
        return if txt.empty?
        if @nodes.last.is_a?(Text)
          @nodes.last.raw_text << txt
        else
          @nodes << Text.new(txt)
        end
      end

      def inline_eol?
        @context.current =~ /^($|<\/ref>|}})/
      end

      def scan_and_inline(pattern, options = {})
        InlineParser.new(@context).parse_until(pattern, options)
      end

      def process_formatting(match)
        case match
        when "'''''"
          node(BoldItalic, scan_and_inline(/(''''')/, inline_eol: true))
        when "'''"
          node(Bold, scan_and_inline(/(''')/, inline_eol: true))
        when "''"
          node(Italic, scan_and_inline(/(''|(?=<\/ref>|}}))/, inline_eol: true))
        when '[['.matchish.guard{ @context.check(@context.re[:file_prefix]) }
          image
        when '[['
          wikilink
        when /\[(.+)/
          external_link($1)
        when '{{'
          template
        when /<ref(.*)\/>/
          reference($1, '')
        when /<ref(.*)>/
          reference($1)
        when '<'
          try_html ||
            @nodes << Text.new(match) # it was not HTML, just accidental <
        when nil
          @context.next!
        end
      end

      def simple_inline(str)
        Parse.inline(str, @context.traits)
      end

      include Commons

      def image
        node(Image, *ImageContentsParser.new(@context).parse)
      end

      def template
        template = Template.new(*TemplateContentsParser.new(@context).parse)
        nodes = @context.traits.expand(template)
        @nodes.push(*nodes)
      end

      # Seems ref's can contain incomplete markup.
      # Or it may be rathe systematic problem (any "inline markup"
      # can be auto-closed at paragraph level?).
      # At least, http://fr.wikipedia.org/wiki/Argentine has <ref>,
      # inside which there's only one opening '' (italic), without closing.
      # And everything works.
      def reference(attr, closed = false)
        children = closed ? Nodes[] : scan_and_inline(/<\/ref>/, allow_paragraphs: true)
        node(Ref, children, parse_params(attr))
      end

      # http://en.wikipedia.org/wiki/Help:Link#Wikilinks
      # [[abc]]
      # [[a|b]]
      def wikilink
        link = @context.scan_continued_until(/\||\]\]/)
        if @context.matched == '|'
          caption = scan_and_inline(/\]\]/)
        end
        link(Wikilink, link, caption)
      end

      # http://en.wikipedia.org/wiki/Help:Link#External_links
      # [http://www.example.org]
      # [http://www.example.org link name]
      def external_link(protocol)
        link = @context.scan_continued_until(/\s+|\]/)
        if @context.matched =~ /\s+/
          caption = scan_and_inline(/\]/)
        end
        link(ExternalLink, protocol + link, caption)
      end

      def link(klass, link, caption)
        node(klass, link, caption)
      end

      def try_html
        case
        when @context.check(/\/[a-z]+>/)
          # lonely closing tag
          @context.skip(/\//)
          tag = @context.scan(/[a-z]+/)
          @context.skip(/>/)
          node(HTMLClosingTag, tag)
        when @context.check(/br\s*>/)
          @context.skip(/br\s*>/)
          node(HTMLTag, 'br', {}, Nodes[])

        when @context.check(%r{[a-z]+[^/>]*/>})
          # auto-closing tag
          tag = @context.scan(/[a-z]+/)
          attrs = @context.scan(%r{[^/>]*})
          @context.skip(%r{/>})
          node(HTMLTag, tag, parse_params(attrs))

        when @context.check(/[a-z]+[^>\/]+>/)
          # opening tag
          tag = @context.scan(/[a-z]+/)
          attrs = @context.scan(/[^>]+/)
          @context.skip(/>/)
          contents = scan_and_inline(/<\/#{tag}>|(?=}}|<\/ref>)/, inline_eol: true)
          if @context.matched =~ /<\/#{tag}>/
            node(HTMLTag, tag, parse_params(attrs), contents)
          else
            node(HTMLOpeningTag, tag, parse_params(attrs))
            @nodes.concat(contents)
          end
        else
          # not an HTML tag at all!
          return false
        end

        true
      end

      def node(klass, *arg)
        @nodes.push(klass.new(*arg))
      end
    end
  end
end
