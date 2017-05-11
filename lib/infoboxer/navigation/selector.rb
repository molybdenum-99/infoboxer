# encoding: utf-8

module Infoboxer
  module Navigation
    module Lookup
      # Incapsulates storage of selectors, used in {Lookup::Node node lookup}.
      #
      # See {Lookup::Node Lookup::Node} for detailed explanation of available selectors.
      class Selector
        include ProcMe

        def initialize(*arg, &block)
          @arg = [arg, block].flatten.compact.map(&method(:sym_to_class))
          @arg.each do |a|
            a.reject! { |_k, v| v.nil? } if a.is_a?(Hash)
          end
        end

        attr_reader :arg

        def ==(other)
          self.class == other.class && arg == other.arg
        end

        def inspect
          "#<Selector(#{@arg.map(&:to_s).join(', ')})>"
        end

        def matches?(node)
          @arg.all? { |a| arg_matches?(a, node) }
        end

        private

        def sym_to_class(a)
          if a.is_a?(Symbol) && a =~ /^[A-Z][a-zA-Z]+$/ && Tree.const_defined?(a)
            Tree.const_get(a)
          else
            a
          end
        end

        def arg_matches?(check, node)
          case check
          when Proc
            check.call(node)
          when Hash
            check.all? { |attr, value| node.respond_to?(attr) && value === node.send(attr) }
          when Symbol
            node.respond_to?(check) && node.send(check)
          else
            check === node
          end
        end
      end
    end
  end
end
