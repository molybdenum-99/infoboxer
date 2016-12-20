# encoding: utf-8
module Infoboxer
  module Tree
    # Base class for all "paragraph-level" nodes: {Paragraph}, {ListItem},
    # {Heading}. It should be convenient to use it in {Navigation::Lookup::Node#_lookup Node#lookup}
    # and similar methods like this:
    #
    # ```ruby
    # page.lookup(:BaseParagraph) # => flat list of paragraph-levels
    # ```
    class BaseParagraph < Compound
      def text
        super.strip + "\n\n"
      end
    end

    # @private
    class EmptyParagraph < Node
      def initialize(text)
        @text = text
      end

      # should never be left in nodes flow
      def empty?
        true
      end

      attr_reader :text
    end

    # @private
    module Mergeable
      def can_merge?(other)
        !closed? && self.class == other.class
      end

      def merge!(other)
        if other.is_a?(EmptyParagraph)
          @closed = true
        else
          [splitter, *other.children].each do |c|
            c.parent = self
            @children << c
          end
          @closed = other.closed?
        end
      end
    end

    # @private
    class MergeableParagraph < BaseParagraph
      include Mergeable

      def can_merge?(other)
        !closed? &&
          (self.class == other.class || other.is_a?(EmptyParagraph))
      end
    end

    # Represents plain text paragraph.
    class Paragraph < MergeableParagraph
      # @private
      # Internal, used by {Parser} for merging
      def splitter
        Text.new(' ')
      end

      # @private
      # Internal, used by {Parser}
      def templates_only?
        children.all? { |c| c.is_a?(Template) || c.is_a?(Text) && c.raw_text.strip.empty? }
      end

      # @private
      # Internal, used by {Parser}
      def to_templates
        children.select(&filter(itself: Template))
      end

      # @private
      # Internal, used by {Parser}
      def to_templates?
        templates_only? ? to_templates : self
      end
    end

    # Represents horisontal ruler splitter. Rarely seen in modern wikis.
    class HR < Node
    end

    # Represents heading.
    #
    # NB: min heading level in MediaWiki is 2, Heading level 1 (page
    # title) is not seen in page flaw.
    class Heading < BaseParagraph
      def initialize(children, level)
        super(children, level: level)
      end

      # @!attribute [r] level
      #   @return [Fixnum] lesser numbers is more important heading
      def_readers :level
    end

    # Represents preformatted text chunk.
    #
    # Paragraph-level thing, can contain many lines of text.
    class Pre < MergeableParagraph
      # @private
      # Internal, used by {Parser}
      def merge!(other)
        if other.is_a?(EmptyParagraph) && !other.text.empty?
          @children.last.raw_text << "\n" << other.text.sub(/^ /, '')
        else
          super
        end
      end

      # @private
      # Internal, used by {Parser} for merging
      def splitter
        Text.new("\n")
      end
    end
  end
end
