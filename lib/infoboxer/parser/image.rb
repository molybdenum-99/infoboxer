# encoding: utf-8
module Infoboxer
  class Parser
    module Image
      include Tree
      
      def image
        @context.skip(re.file_prefix) or
          @context.fail!("Something went wrong: it's not image?")

        path = @context.scan_until(/\||\]\]/)
        attrs = if @context.matched == '|'
          image_attrs
        else
          {}
        end
        Tree::Image.new(path, attrs)
      end

      def image_attrs
        nodes = []

        loop do
          nodes << long_inline(/\||\]\]/)
          break if @context.matched == ']]'
        end

        nodes.map(&method(:image_attr)).
          inject(&:merge).
          reject{|k, v| v.nil? || v.empty?}
      end

      def image_attr(nodes)
        if nodes.count == 1 && nodes.first.is_a?(Text)
          case (str = nodes.first.text)
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
          else # text-only caption
            {caption: nodes}
          end
        else # it's caption, and can have inline markup!
          {caption: nodes}
        end
      end
    end
  end
end
