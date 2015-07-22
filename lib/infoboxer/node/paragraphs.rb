# encoding: utf-8
module Infoboxer
  class BaseParagraph < Compound
    def text
      super.strip + "\n\n"
    end
  end

  class EmptyParagraph < Node
    def initialize(text)
      @text = text
    end

    # should never be left in nodes flow
    def empty?
      true
    end

    attr_reader :text
  end

  module Mergeable
    def can_merge?(other)
      !closed? && self.class == other.class
    end

    def merge!(other)
      if other.is_a?(EmptyParagraph)
        @closed = true
      else
        [splitter, *other.children].each do |c|
          @children << c
        end
        @closed = other.closed?
      end
    end
  end
  
  class MergeableParagraph < BaseParagraph
    include Mergeable

    def can_merge?(other)
      !closed? &&
        (self.class == other.class || other.is_a?(EmptyParagraph))
    end
  end

  class Paragraph < MergeableParagraph
    # for merging
    def splitter
      Text.new(' ')
    end

    def templates_only?
      children.all?{|c| c.is_a?(Template) || c.is_a?(Text) && c.raw_text.strip.empty?}
    end

    def to_templates
      children.select(&filter(itself: Template))
    end

    def to_templates?
      templates_only? ? to_templates : self
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

  class Pre < MergeableParagraph
    def merge!(other)
      if other.is_a?(EmptyParagraph) && !other.text.empty?
        @children.last.raw_text << "\n" << other.text.sub(/^ /, '')
      else
        super
      end
    end

    # for merging
    def splitter
      Text.new("\n")
    end
  end
end
