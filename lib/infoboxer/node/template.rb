# encoding: utf-8
module Infoboxer
  class TemplateVariable < Compound
    attr_reader :name

    def initialize(name, children = Nodes[])
      super(children)
      @name = name
    end

    def empty?
      false
    end

    def descr
      "#{clean_class}(#{name})"
    end

    def _eq(other)
      other.name == name && other.children == children
    end
  end
  
  class Template < Node
    attr_reader :name, :variables

    def initialize(name, variables = Nodes[])
      super(extract_params(variables))
      @name, @variables = name, variables
    end

    def _eq(other)
      other.name == name && other.variables == variables
    end

    def inspect(depth = 0)
      if depth.zero?
        "#<#{descr}: #{variables.inspect_no_p(depth)}>"
      else
        "#<#{descr}>"
      end
    end

    def to_tree(level = 0)
      '  ' * level + "<#{clean_class}(#{name})>\n" +
        variables.map{|var| var.to_tree(level+1)}.join
    end

    def fetch(var)
      variables.find(name: var)
    end

    private
      def descr
        "#{clean_class}(#{name})"
      end
      
      def extract_params(vars)
        # NB: backports' to_h is cleaner but has performance penalty :(
        Hash[*vars.
          select{|v| v.children.count == 1 && v.children.first.is_a?(Text)}.
          map{|v| [v.name, v.children.first.raw_text]}.flatten(1)]
      end

      def inspect_variables(depth)
        variables.to_a[0..1].map{|name, var| "#{name}: #{var.inspect(depth+1)}"}.join(', ') +
          (variables.count > 2 ? ', ...' : '')
      end
  end
end
