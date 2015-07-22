# encoding: utf-8
module Infoboxer
  class Text < Node
    attr_accessor :raw_text
    
    def initialize(text, params = {})
      super(params)
      @raw_text = text
    end

    def text
      @text ||= decode(@raw_text)
    end

    def to_tree(level = 0)
      "#{indent(level)}#{text} <#{descr}>\n"
    end

    def can_merge?(other)
      other.is_a?(String) || other.is_a?(Text)
    end

    def merge!(other)
      if other.is_a?(String)
        @raw_text << other
      elsif other.is_a?(Text)
        @raw_text << other.raw_text
      else
        fail("Not mergeable into text: #{other.inspect}")
      end
    end

    def empty?
      raw_text.empty?
    end

    private

    def _eq(other)
      text == other.text
    end
  end
end
