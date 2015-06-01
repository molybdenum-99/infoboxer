# encoding: utf-8
module Infoboxer
  class Ref < Compound
    # because we want "clean" text,
    # without references & footnotes messed up in it
    def to_text
      '' 
    end
  end
end
