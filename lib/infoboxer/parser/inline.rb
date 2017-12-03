module Infoboxer
  class Parser
    module Inline
      include Tree

      def inline(until_pattern = nil)
        start = @context.lineno
        nodes = Nodes[]
        guarded_loop do
          chunk = @context.scan_until(re.inline_until_cache[until_pattern])
          nodes << chunk

          break if @context.matched_inline?(until_pattern)

          nodes << inline_formatting(@context.matched) unless @context.matched.empty?

          if @context.eof?
            break unless until_pattern
            @context.fail!("#{until_pattern} not found, starting from #{start}")
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
        guarded_loop do
          # FIXME: quick and UGLY IS HELL JUST TRYING TO MAKE THE SHIT WORK
          chunk =
            if @context.inline_eol_sign == /^\]/
              @context.scan_until(re.short_inline_until_cache_brackets[until_pattern])
            elsif @context.inline_eol_sign == /^\]\]/
              @context.scan_until(re.short_inline_until_cache_brackets2[until_pattern])
            else
              @context.scan_until(re.short_inline_until_cache[until_pattern])
            end
          nodes << chunk

          break if @context.matched_inline?(until_pattern)

          nodes << inline_formatting(@context.matched)

          break if @context.inline_eol?(until_pattern)
        end

        nodes
      end

      def long_inline(until_pattern = nil)
        nodes = Nodes[]
        guarded_loop do
          chunk = @context.scan_until(re.inline_until_cache[until_pattern])
          nodes << chunk

          break if @context.matched?(until_pattern)

          nodes << inline_formatting(@context.matched) unless @context.matched.empty?

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

      def inline_formatting(match) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
        case match
        when "'''''"
          BoldItalic.new(short_inline(/'''''/))
        when "'''"
          Bold.new(short_inline(/'''/))
        when "''"
          Italic.new(short_inline(/''/))
        when '[['
          if @context.check(re.file_namespace)
            image
          else
            wikilink
          end
        when /\[(.+)/
          external_link(Regexp.last_match(1))
        when '{{'
          template
        when /<nowiki([^>]*)>/
          nowiki(Regexp.last_match(1))
        when %r{<ref([^>]*)/>}
          reference(Regexp.last_match(1), true)
        when /<ref([^>]*)>/
          reference(Regexp.last_match(1))
        when /<math>/
          math
        when /<gallery([^>]*)>/
          gallery(Regexp.last_match(1))
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
        if @context.matched == '|'
          @context.push_eol_sign(/^\]\]/)
          caption = inline(/\]\]/)
          @context.pop_eol_sign
        end
        name, namespace = link.split(':', 2).reverse
        lnk, params =
          if @context.traits.namespace?(namespace)
            [link, {namespace: namespace}]
          elsif @context.traits.interwiki?(namespace)
            [name, {interwiki: namespace}]
          else
            [link, {}]
          end

        puts @context.rest if lnk.nil?
        Wikilink.new(lnk, caption, **params)
      end

      # http://en.wikipedia.org/wiki/Help:Link#External_links
      # [http://www.example.org]
      # [http://www.example.org link name]
      def external_link(protocol)
        link = @context.scan_continued_until(/\s+|\]/)
        if @context.matched =~ /\s+/
          @context.push_eol_sign(/^\]/)
          caption = short_inline(/\]/)
          @context.pop_eol_sign
        end
        ExternalLink.new(protocol + link, caption)
      end

      def reference(param_str, closed = false)
        children = closed ? Nodes[] : long_inline(%r{</ref>})
        Ref.new(children, parse_params(param_str))
      end

      def math
        Math.new(@context.scan_continued_until(%r{</math>}))
      end

      def nowiki(tag_rest)
        if tag_rest.end_with?('/')
          Text.new('')
        else
          Text.new(@context.scan_continued_until(%r{</nowiki>}))
        end
      end

      def gallery(tag_rest)
        params = parse_params(tag_rest)
        images = []
        guarded_loop do
          @context.next! if @context.eol?
          path = @context.scan_until(%r{</gallery>|\||$})
          attrs = @context.matched == '|' ? gallery_image_attrs : {}
          unless path.empty?
            images << Tree::Image.new(path.sub(/^#{re.file_namespace}/, ''), attrs)
          end
          break if @context.matched == '</gallery>'
        end
        Gallery.new(images, params)
      end

      def gallery_image_attrs
        nodes = []

        guarded_loop do
          nodes << short_inline(%r{\||</gallery>})
          break if @context.eol? || @context.matched?(%r{</gallery>})
        end

        nodes.map(&method(:image_attr))
             .inject(&:merge)
             .reject { |_k, v| v.nil? || v.empty? }
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
