# encoding: utf-8
module Infoboxer
  class Node
    class Selector
      include ProcMe
      
      def initialize(*arg, &block)
        @arg = [arg, block].flatten.compact
        
        @checks = @arg.map{|a|
          construct_check(a)
        }.flatten
      end

      def inspect
        "#<Selector(#{@arg.map(&:to_s).join(', ')})>"
      end

      def matches?(node)
        @checks.all?(&call(call: node))
      end

      private

      def construct_check(obj)
        case obj
        when Proc
          obj
        when Hash
          obj.map{|attr, value|
            ->(node){node.respond_to?(attr) && value === node.send(attr)}
          }
        when Symbol
          ->(node){node.respond_to?(obj) && node.send(obj)}
        else
          ->(node){obj === node}
        end
      end
    end
  end
end
