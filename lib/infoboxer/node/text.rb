# encoding: utf-8
module Infoboxer
  class Text < Node
    attr_reader :raw_text
    
    def initialize(text, params = {})
      super(params)
      @raw_text = text
    end

    def text
      @text ||= decode(@raw_text)
    end

    def inspect(depth = 0)
      depth < 2 ? "#<#{descr}: #{shorten_text}>" : super
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
