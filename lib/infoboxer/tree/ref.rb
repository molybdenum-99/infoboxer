# encoding: utf-8
module Infoboxer
  module Tree
    # Represents footnote.
    #
    # Is not rendered in text flow, so, wikitext like
    #
    # ```
    # ...pushed it back into underdevelopment,<ref>...tons of footnote text...</ref> though it nevertheless...
    # ```
    # when parsed and {Node#text} called, will return text like:
    #
    # ```
    # ...pushed it back into underdevelopment, though it nevertheless...
    # ```
    # ...which most times is most reasonable thing to do.
    class Ref < Compound
      # @!attribute [r] name
      def_readers :name

      # @private
      # Internal, used by {Parser}
      def empty?
        # even empty tag should not be dropped!
        false
      end
      
      def text
        # because we want "clean" text,
        # without references & footnotes messed up in it
        '' 
      end
    end
  end
end
