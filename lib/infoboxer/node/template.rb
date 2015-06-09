# encoding: utf-8
module Infoboxer
  class Template < Node
    def initialize(name, variables = {})
      @name, @variables = name, variables
    end

    attr_reader :name, :variables

    def _eq(other)
      other.name == name && other.variables == variables
    end

    def inspect(depth = 0)
      if depth.zero?
        "#<#{clean_class}:#{name}(#{inspect_variables(depth)})>"
      else
        "#<#{clean_class}:#{name}>"
      end
    end

    def to_tree(level = 0)
      '  ' * level + "<#{clean_class}(#{name})>\n" +
        variables.map{|k, v| var_to_tree(k, v, level+1)}.join
    end

    private

      def var_to_tree(name, var, level)
        indent(level) + "#{name}:\n" + var.map{|n| n.to_tree(level+1)}.join
      end

      def inspect_variables(depth)
        variables.to_a[0..1].map{|name, var| "#{name}: [#{inspect_var(var)}]"}.join(', ') +
          (variables.count > 2 ? ', ...' : '')
      end

      def inspect_var(nodes)
        nodes.first.inspect(1) + (nodes.count > 1 ? ', ...' : '')
      end
  end
end
