# encoding: utf-8

module Infoboxer
  module Tree
    # Represents plain text node.
    #
    # Think of it like this: if you have paragraph
    # ```
    # Some paragraph with ''italic'' and [wikilink].
    # ```
    # ...then it will be parsed as a sequence of `[Text`, {Italic}, `Text`,
    # {Wikilink}, `Text]`.
    #
    class Text < Node
      # Text fragment without decodint of HTML entities.
      attr_accessor :raw_text

      def initialize(text, **params)
        super(params)
        @raw_text = text
      end

      # See {Node#text}
      def text
        @text ||= decode(@raw_text)
      end

      # See {Node#to_tree}
      def to_tree(level = 0)
        "#{indent(level)}#{text} <#{descr}>\n"
      end

      # @private
      # Internal, used by {Parser}
      def can_merge?(other)
        other.is_a?(String) || other.is_a?(Text)
      end

      # @private
      # Internal, used by {Parser}
      def merge!(other)
        if other.is_a?(String)
          @raw_text << other
        elsif other.is_a?(Text)
          @raw_text << other.raw_text
        else
          fail("Not mergeable into text: #{other.inspect}")
        end
      end

      # @private
      # Internal, used by {Parser}
      def empty?
        raw_text.empty?
      end

      private

      def _eq(other)
        text == other.text
      end
    end
  end
end
