# encoding: utf-8
require 'htmlentities'

module Infoboxer
  class Node
    include ProcMe
    
    def initialize(params = {})
      @params = params
    end

    attr_reader :params
    attr_accessor :parent
    
    def can_merge?(other)
      false
    end

    def ==(other)
      self.class == other.class && _eq(other)
    end

    def to_tree(level = 0)
      indent(level) + "<#{descr}>\n"
    end

    def matches?(*args, &block)
      _matches?(Selector.new(*args, &block))
    end

    def lookup(*args, &block)
      _lookup(Selector.new(*args, &block))
    end

    def lookup_parent(*args, &block)
      _lookup_parent(Selector.new(*args, &block))
    end

    def _lookup_parent(selector)
      case
      when !parent
        Nodes[]
      when parent._matches?(selector)
        Nodes[parent, *parent._lookup_parent(selector)]
      else
        parent._lookup_parent(selector)
      end
    end

    def _matches?(selector)
      selector.matches?(self)
    end

    def _lookup(selector)
      _matches?(selector) ? self : nil
    end
    
    private

    def clean_class
      self.class.name.sub(/^.*::/, '')
    end

    def descr
      if params.empty?
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

  module Mergeable
    def can_merge?(other)
      self.class == other.class && !closed?
    end

    def merge!(other)
      @children.concat(other.children)
      @closed = other.closed?
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
