# encoding: utf-8
module Infoboxer
  class BaseParagraph < Compound
  end

  class Paragraph < BaseParagraph
    include Mergeable
  end

  class HR < Node
  end

  class Heading < BaseParagraph
    def initialize(children, level)
      super(children, level: level)
    end

    def_readers :level
  end

  class Pre < BaseParagraph
    include Mergeable
  end
end
