module Infoboxer
  module Tree
    # Represents node of math formulae marked with TeX
    #
    # See also: https://en.wikipedia.org/wiki/Help:Displaying_a_formula
    class Math < Text
      def text
        "<math>#{super}</math>"
      end
    end
  end
end
