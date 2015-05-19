# encoding: utf-8
module Infoboxer
  class Template < Node
    def initialize(name, variables)
      @name, @variables = name, variables
    end

    attr_reader :name, :variables

    def inspect
      "#<#{clean_class}:#{name}#{variables}>"
    end

    def to_tree(level = 0)
      '  ' * level + "#{clean_class}:#{name}\n" +
        variables.map{|v| var_to_tree(v, level+1)}.join
    end

    def var_to_tree(var, level)
      case var
      when Hash
        '  ' * level + "| #{var.keys.first}\n" +
          var.values.first.map{|v| v.to_tree(level+1)}.join
      when Nodes
        '  ' * level + "|\n" +
          var.map{|v| v.to_tree(level+1)}.join
      end
    end
  end
end
