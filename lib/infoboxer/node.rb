# encoding: utf-8
require 'htmlentities'
require_relative 'node/tree_navigation'

module Infoboxer
  class Node
    include ProcMe
    
    def initialize(params = {})
      @params = params
    end

    attr_reader :params
    attr_accessor :parent

    def ==(other)
      self.class == other.class && _eq(other)
    end

    def index
      parent ? parent.index_of(self) : 0
    end

    def siblings
      parent ? parent.children - [self] : Nodes[]
    end
    
    def can_merge?(other)
      false
    end

    def empty?
      false
    end

    def to_tree(level = 0)
      indent(level) + "<#{descr}>\n"
    end

    def to_text
      ''
    end

    def inspect(depth = 0)
      depth < 2 ? "#<#{descr}>" : "#<#{clean_class}>"
    end

    # just aliases will not work when to_text will be redefined in subclasses
    def text
      to_text
    end
    
    def to_s
      to_text
    end

    include TreeNavigation

    private

    def clean_class
      self.class.name.sub(/^.*::/, '')
    end

    def descr
      if !params || params.empty?
        "#{clean_class}"
      else
        "#{clean_class}(#{show_params})"
      end
    end

    def show_params(prms = nil)
      (prms || params).map{|k, v| "#{k}: #{v.inspect}"}.join(', ')
    end

    def indent(level)
      '  ' * level
    end

    def _eq(other)
      fail(NotImplementedError, "#_eq should be defined in subclasses")
    end

    def decode(str)
      Node.coder.decode(str)
    end
    
    class << self
      def def_readers(*keys)
        keys.each do |k|
          define_method(k){ params[k] }
        end
      end

      def coder
        @coder ||= HTMLEntities.new
      end
    end
  end
end

require_relative 'node/text'
require_relative 'node/compound'
require_relative 'node/inline'
require_relative 'node/image'
require_relative 'node/html'
require_relative 'node/paragraphs'
require_relative 'node/list'
require_relative 'node/template'
require_relative 'node/table'
require_relative 'node/ref'

require_relative 'node/selector'
