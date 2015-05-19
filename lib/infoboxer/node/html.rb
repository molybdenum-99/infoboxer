# encoding: utf-8
module Infoboxer
  class HTMLTag < Compound
    def initialize(tag, attrs, children = Nodes.new)
      super(children, attrs)
      @tag = tag
    end

    attr_reader :tag
    alias_method :attrs, :params

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
