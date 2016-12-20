# encoding: utf-8
module Infoboxer
  module Tree
    module HTMLTagCommons
      BLOCK_TAGS = %w[div p br].freeze # FIXME: are some other used in WP?

      def text
        super + (BLOCK_TAGS.include?(tag) ? "\n" : '')
      end
    end

    # Represents HTML tag, surrounding some contents.
    class HTMLTag < Compound
      def initialize(tag, attrs, children = Nodes.new)
        super(children, attrs)
        @tag = tag
      end

      attr_reader :tag
      alias_method :attrs, :params

      include HTMLTagCommons

      # @private
      # Internal, used by {Parser}.
      def empty?
        # even empty tag, for ex., <br>, should not be dropped!
        false
      end

      private

      def descr
        "#{clean_class}:#{tag}(#{show_params})"
      end
    end

    # Represents orphan opening HTML tag.
    #
    # NB: Infoboxer not tries to parse entire structure of HTML-heavy
    # MediaWiki articles. So, if you have `<div>` at line 150 and closing
    # `</div>` at line 875, there would be orphane `HTMLOpeningTag` and
    # {HTMLClosingTag}. It is not always convenient, but reasonable enough.
    #
    class HTMLOpeningTag < Node
      def initialize(tag, attrs)
        super(attrs)
        @tag = tag
      end

      attr_reader :tag
      alias_method :attrs, :params

      include HTMLTagCommons

      private

      def descr
        "#{clean_class}:#{tag}(#{show_params})"
      end
    end

    # Represents orphan closing HTML tag. See {HTMLOpeningTag} for
    # explanation.
    class HTMLClosingTag < Node
      def initialize(tag)
        @tag = tag
      end

      attr_reader :tag

      def descr
        "#{clean_class}:#{tag}"
      end
    end
  end
end
