# encoding: utf-8
module Infoboxer
  class BaseParagraph < Compound
    def to_text
      super + "\n\n"
    end
  end

  class Paragraph < BaseParagraph
    include Mergeable

    # for merging
    def splitter
      [Text.new(' ')]
    end
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

    # for merging
    def splitter
      [Text.new("\n")]
    end
  end
end
