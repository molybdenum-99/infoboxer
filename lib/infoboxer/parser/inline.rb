# encoding: utf-8
module Infoboxer
  class Parser
    module Inline
      def inline(until_pattern = nil)
        nodes = Nodes[]
        loop do
          chunk = @context.scan_until(re.inline_until_cache[until_pattern])
          nodes << chunk

          break if @context.matched_inline?(until_pattern)

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

          break if @context.matched_inline?(until_pattern) || @context.inline_eol?

          nodes << inline_formatting(@context.matched)
        end
        
        nodes
      end

      def long_inline(until_pattern = nil)
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
            @context.next!
            paragraphs(until_pattern).each do |p|
              nodes << p
            end
            break
          end
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
          when '{{'
            template
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
      end

      require_relative 'image'
      require_relative 'html'
      require_relative 'template'
      include Infoboxer::Parser::Image
      include Infoboxer::Parser::HTML
      include Infoboxer::Parser::Template
  end
end
