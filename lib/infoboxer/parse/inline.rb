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

      def parse(full = false)
        @text = ''
        until @context.eof?
          str = @context.scan_until(@context.re[:formatting])
          @text << str.to_s

          if @context.matched.nil?
            @text << @context.rest
            if full
              @context.next!
              @text << ' ' unless @context.eof?
            else
              break
            end
          else
            process_formatting(@context.matched)
          end
        end
        ensure_text!
        @nodes
      end

      private

      def process_formatting(match)
        case match
        when "'''''"
          node(BoldItalic, simple_inline(@context.scan_through_until(/('''''|$)/)))
        when "'''"
          node(Bold, simple_inline(@context.scan_through_until(/('''|$)/)))
        when "''"
          node(Italic, simple_inline(@context.scan_through_until(/(''|$)/)))
        when '[['.matchish.guard{ @context.check(@context.re[:file_prefix]) }
          image(@context.scan_through_until(/\]\]/))
        when '[['
          wikilink(@context.scan_through_until(/\]\]/))
        when /\[(.+)/
          external_link($1, @context.scan_through_until(/\]/))
        when '{{'
          template(@context.scan_through_until(/}}/))
        when /<ref(.*)\/>/
          reference($1, '')
        when /<ref(.*)>/
          reference($1, @context.scan_through_until(/<\/ref>/))
        when '<'
          try_html ||
            @text << match # it was not HTML, just accidental <
        end
      end

      def simple_inline(str)
        Parse.inline(str, @context.traits)
      end

      include Commons

      def image(str)
        node(Image, *ImageContentsParser.new(str, @context.traits).parse)
      end

      def template(str)
        ensure_text!

        template = Template.new(*TemplateContentsParser.new(str, @context.traits).parse)
        nodes = @context.traits.expand(template)
        @nodes.push(*nodes)
      end

      # Seems ref's can contain incomplete markup.
      # Or it may be rathe systematic problem (any "inline markup"
      # can be auto-closed at paragraph level?).
      # At least, http://fr.wikipedia.org/wiki/Argentine has <ref>,
      # inside which there's only one opening '' (italic), without closing.
      # And everything works.
      def reference(attr, str)
        nodes = begin
          Parse.paragraphs(str, @context.traits)
        rescue ParsingError
          Text.new(str)
        end
        
        node(Ref, nodes, parse_params(attr)) 
      end

      # http://en.wikipedia.org/wiki/Help:Link#Wikilinks
      # [[abc]]
      # [[a|b]]
      def wikilink(str)
        link(Wikilink, str, '|')
      end

      # http://en.wikipedia.org/wiki/Help:Link#External_links
      # [http://www.example.org]
      # [http://www.example.org link name]
      def external_link(protocol, str)
        link(ExternalLink, protocol + str, /\s+/)
      end

      def link(klass, str, split_pattern)
        link, label = str.split(split_pattern, 2)
        node(klass, link || str, label && simple_inline(label))
      end

      def try_html
        case
        when @context.check(/\/[a-z]+>/)
          # lonely closing tag
          @context.skip(/\//)
          tag = @context.scan(/[a-z]+/)
          @context.skip(/>/)
          node(HTMLClosingTag, tag)

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
          if (contents = @context.scan_until(/<\/#{tag}>/))
            node(HTMLTag, tag, parse_params(attrs), simple_inline(contents.sub("</#{tag}>", '')))
          else
            node(HTMLOpeningTag, tag, parse_params(attrs))
          end
        else
          # not an HTML tag at all!
          return false
        end

        true
      end

      def node(klass, *arg)
        ensure_text!
        @nodes.push(klass.new(*arg))
      end

      def ensure_text!
        unless @text.empty?
          @nodes.push(Text.new(@text))
          @text = ''
        end
      end
    end
  end
end
