# encoding: utf-8
module Infoboxer
  class TemplateVariable < Compound
  end
  
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
        indent(level) + "#{name}:\n" + var.to_tree(level+1)
      end

      def inspect_variables(depth)
        variables.to_a[0..1].map{|name, var| "#{name}: #{var.inspect(depth+1)}"}.join(', ') +
          (variables.count > 2 ? ', ...' : '')
      end
  end
end
