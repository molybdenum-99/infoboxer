# encoding: utf-8
module Infoboxer
  class Node
    class Selector
      include ProcMe
      
      def initialize(*arg, &block)
        @arg = [arg, block].flatten.compact
        @arg.each do |a|
          a.reject!{|k, v| v.nil?} if a.is_a?(Hash)
        end
      end

      def inspect
        "#<Selector(#{@arg.map(&:to_s).join(', ')})>"
      end

      def matches?(node)
        @arg.all?{|a| arg_matches?(a, node)}
      end

      private

      def arg_matches?(check, node)
        case check
        when Proc
          check.call(node)
        when Hash
          check.all?{|attr, value|
            node.respond_to?(attr) && value === node.send(attr)
          }
        when Symbol
          node.respond_to?(check) && node.send(check)
        else
          check === node
        end
      end
    end
  end
end
