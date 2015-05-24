# encoding: utf-8
module Infoboxer
  class Paragraph < Compound
    include Mergeable
  end

  class HR < Node
  end

  class Heading < Compound
    def initialize(children, level)
      super(children, level: level)
    end

    def_readers :level
  end

  class Pre < Compound
    include Mergeable
  end
end
