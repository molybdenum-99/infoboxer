# encoding: utf-8

module Infoboxer
  class Parser
    module Image
      include Tree

      def image
        @context.skip(re.file_namespace) or
          @context.fail!("Something went wrong: it's not image?")

        path = @context.scan_until(/\||\]\]/)
        attrs = @context.matched == '|' ? image_attrs : {}
        Tree::Image.new(path, attrs)
      end

      def image_attrs
        nodes = []

        loop do
          nodes << long_inline(/\||\]\]/)
          break if @context.matched == ']]'
        end

        nodes.map(&method(:image_attr))
             .inject(&:merge)
             .reject { |_k, v| v.nil? || v.empty? }
      end

      def image_attr(nodes)
        # it's caption, and can have inline markup!
        return {caption: ImageCaption.new(nodes)} unless nodes.count == 1 && nodes.first.is_a?(Text)

        case (str = nodes.first.text)
        when /^(thumb)(?:nail)?$/, /^(frame)(?:d)?$/
          {type: Regexp.last_match(1)}
        when 'frameless'
          {type: str}
        when 'border'
          {border: str}
        when /^(baseline|middle|sub|super|text-top|text-bottom|top|bottom)$/
          {alignment: str}
        when /^(\d*)(?:x(\d+))?px$/
          {width: Regexp.last_match(1), height: Regexp.last_match(2)}
        when /^link=(.*)$/i
          {link: Regexp.last_match(1)}
        when /^alt=(.*)$/i
          {alt: Regexp.last_match(1)}
        else # text-only caption
          {caption: ImageCaption.new(nodes)}
        end
      end
    end
  end
end
