# encoding: utf-8
module Infoboxer
  class Image < Node
    def initialize(path, params = {})
      @caption = params.delete(:caption)
      super({path: path}.merge(params))
    end

    attr_reader :caption

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
            caption.map(&call(to_tree: level+2)).join
        else
          ''
        end
    end
  end
end
