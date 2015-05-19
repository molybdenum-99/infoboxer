# encoding: utf-8
module Infoboxer
  class Paragraph < Compound
  end

  class HR < Node
  end

  class Heading < Compound
    def initialize(children, level)
      super(children, level: level)
    end

    def_readers :level

    def can_merge?(*)
      false
    end
  end

  class ListItem < Compound
    def initialize(text, marker)
      super(text)
      @marker = marker
    end

    attr_reader :marker
  end

  class Pre < Compound
  end
end
