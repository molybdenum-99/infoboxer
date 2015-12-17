# encoding: utf-8
module Infoboxer
  module Tree
    # Represents image (or other media file).
    #
    # See [Wikipedia Tutorial](https://en.wikipedia.org/wiki/Wikipedia:Extended_image_syntax)
    # for explanation of attributes.
    class Image < Node
      def initialize(path, params = {})
        @caption = params.delete(:caption)
        super({path: path}.merge(params))
      end

      # Image caption. Can have (sometimes many) other nodes inside.
      #
      # @return [Nodes]
      attr_reader :caption

      # @!attribute [r] path 
      # @!attribute [r] type
      # @!attribute [r] location 
      # @!attribute [r] alignment
      # @!attribute [r] link
      # @!attribute [r] alt 

      def_readers :path, :type,
        :location, :alignment, :link,
        :alt

      def border?
        !params[:border].to_s.empty?
      end

      def width
        params[:width].to_i
      end

      def height
        params[:height].to_i
      end

      def to_tree(level = 0)
        super(level) +
          if caption && !caption.empty?
            indent(level+1) + "caption:\n" +
              caption.children.map(&call(to_tree: level+2)).join
          else
            ''
          end
      end
    end

    # Represents image caption.
    class ImageCaption < Compound
    end
  end
end
