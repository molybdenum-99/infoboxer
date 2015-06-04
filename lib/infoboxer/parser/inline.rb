# encoding: utf-8
require_relative 'image'
require_relative 'template'

# http://www.mediawiki.org/wiki/Help:Formatting
module Infoboxer
  module Parse
    class InlineParser
      def initialize(str, context)
        @context = context
        @str = str.gsub(/[\r\n]/m, ' ')

        @scanner = StringScanner.new(str)
        @nodes = Nodes.new
      end

      def parse
        @text = ''
        formatting_start = /(
            '{2,5}        |     # bold, italic
            \[\[          |     # link
            {{            |     # template
            \[[a-z]+:\/\/ |     # external link
            <ref[^>]*>    |     # reference
            <                   # HTML tag
          )/x
        until scanner.eos?
          str = scanner.scan_until(formatting_start)
          @text << str.sub(scanner.matched, '') if str

          match = scanner.matched
          case match
          when "'''''"
            node(BoldItalic, inline(scan_simple(/'''''/)))
          when "'''"
            node(Bold, inline(scan_simple(/'''/)))
          when "''"
            node(Italic, inline(scan_simple(/''/)))
          when '[['.matchish.guard{ scanner.check(/#{@context.file_prefix}:/) }
            image(scan(/\[\[/, /\]\]/))
          when '[['
            wikilink(scan(/\[\[/, /\]\]/))
          when /\[(.+)/
            external_link($1, scan(/\[/, /\]/))
          when '{{'
            template(scan(/{{/, /}}/))
          when /<ref(.*)\/>/
            reference($1, '')
          when /<ref(.*)>/
            reference($1, scan(/<ref>/, /<\/ref>/))
          when '<'
            try_html ||
              @text << match # it was not HTML, just accidental <
          when nil
            @text << scanner.rest
            break
          end        
        end
        ensure_text!
        @nodes
      rescue => e
        raise e.exception("Error while parsing #{@str}: #{e.message}").
          tap{|e_| e_.set_backtrace(e.backtrace)}
      end

      private

      def inline(str)
        InlineParser.new(str, @context).parse
      end

      # simple scan: just text until pattern
      def scan_simple(after)
        scanner.scan_until(after).tap{|res|
          res or fail(ParsingError, "#{after} not found in #{scanner.rest}")
        }.sub(after, '')
      end

      include Commons

      def scan(before, after)
        scan_continued(scanner, before, after, @context.next_lines)
      end

      def image(str)
        node(Image, *ImageContentsParser.new(str, @context).parse)
      end

      def template(str)
        ensure_text!

        template = Template.new(*TemplateContentsParser.new(str, @context).parse)
        nodes = if @context
          @context.expand(template)
        else
          template
        end
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
          Parse.paragraphs(str, @context)
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
        node(klass, link || str, label && inline(label))
      end

      def try_html
        case
        when scanner.check(/\/[a-z]+>/)
          # lonely closing tag
          scanner.skip(/\//)
          tag = scanner.scan(/[a-z]+/)
          scanner.skip(/>/)
          node(HTMLClosingTag, tag)

        when scanner.check(%r{[a-z]+[^/>]*/>})
          # auto-closing tag
          tag = scanner.scan(/[a-z]+/)
          attrs = scanner.scan(%r{[^/>]*})
          scanner.skip(%r{/>})
          node(HTMLTag, tag, parse_params(attrs))

        when scanner.check(/[a-z]+[^>\/]+>/)
          # opening tag
          tag = scanner.scan(/[a-z]+/)
          attrs = scanner.scan(/[^>]+/)
          scanner.skip(/>/)
          if (contents = scanner.scan_until(/<\/#{tag}>/))
            node(HTMLTag, tag, parse_params(attrs), inline(contents.sub("</#{tag}>", '')))
          else
            node(HTMLOpeningTag, tag, parse_params(attrs))
          end
        else
          # not an HTML tag at all!
          return false
        end

        true
      end

      attr_reader :scanner

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
