# encoding: utf-8
module Infoboxer
  module Tree
    class Var < Compound
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
    
    class Template < Compound
      attr_reader :name, :variables

      def initialize(name, variables = Nodes[])
        super(Nodes[], extract_params(variables))
        @name  = name 
        @variables = Nodes[*variables].each{|v| v.parent = self}
      end

      def _eq(other)
        other.name == name && other.variables == variables
      end

      def to_tree(level = 0)
        '  ' * level + "<#{descr}>\n" +
          variables.map{|var| var.to_tree(level+1)}.join
      end

      def empty?
        false
      end

      protected

      def clean_class
        if self.class.template_name == name
          self.class.clean_name
        else
          "#{self.class.clean_name}[#{name}]"
        end
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
end
