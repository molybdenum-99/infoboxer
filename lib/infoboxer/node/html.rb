# encoding: utf-8
module Infoboxer
  module HTMLTagCommons
    BLOCK_TAGS = %w[div p br] # FIXME: are some other used in WP?

    def to_text
      BLOCK_TAGS.include?(tag) ? "\n" : ''
    end
  end
  
  class HTMLTag < Compound
    def initialize(tag, attrs, children = Nodes.new)
      super(children, attrs)
      @tag = tag
    end

    attr_reader :tag
    alias_method :attrs, :params

    include HTMLTagCommons

    # even empty tag, for ex., <br>, should not be dropped!
    def empty?
      false
    end
    
    private

    def descr
      "#{clean_class}:#{tag}(#{show_params})"
    end
  end

  class HTMLOpeningTag < Node
    def initialize(tag, attrs)
      super(attrs)
      @tag = tag
    end
    
    attr_reader :tag
    alias_method :attrs, :params

    include HTMLTagCommons
    
    private

    def descr
      "#{clean_class}:#{tag}(#{show_params})"
    end
  end

  class HTMLClosingTag < Node
    def initialize(tag)
      @tag = tag
    end

    attr_reader :tag

    def descr
      "#{clean_class}:#{tag}"
    end
  end
end
