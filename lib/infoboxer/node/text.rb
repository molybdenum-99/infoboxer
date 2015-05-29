# encoding: utf-8
module Infoboxer
  class Text < Node
    def initialize(text, params = {})
      super(params)
      @text = decode(text)
    end

    attr_reader :text

    def inspect
      "#<#{descr}: #{shorten_text}>"
    end

    def to_tree(level = 0)
      "#{indent(level)}#{text} <#{descr}>\n"
    end

    alias_method :to_text, :text

    private

    MAX_CHARS = 30

    def shorten_text
      text.length > MAX_CHARS ? text[0..MAX_CHARS].inspect + '...' : text.inspect
    end

    def _eq(other)
      text == other.text
    end
  end
end
