# encoding: utf-8
module Infoboxer
  class Template < Node
    def initialize(name, vars = [])
      @name, @vars = name, vars
    end

    attr_reader :name, :vars

    def variables
      Hash[*vars.each_with_index.flat_map{|v, i|
        case v
        when Hash
          [v.keys.first, v.values.first]
        else
          [i+1, v]
        end
        }
      ]
    end

    def _eq(other)
      other.name == name && other.vars == vars
    end

    def inspect
      "#<#{clean_class}:#{name}#{variables}>"
    end

    def to_tree(level = 0)
      '  ' * level + "<#{clean_class}(#{name})>\n" +
        variables.map{|k, v| var_to_tree(k, v, level+1)}.join
    end

    def var_to_tree(name, var, level)
      indent(level) + "#{name}:\n" + var.map{|n| n.to_tree(level+1)}.join
    end
  end
end
