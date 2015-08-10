# encoding: utf-8
module Infoboxer
  module Tree
    # Template variable.
    #
    # It's basically the thing with name and ANY nodes inside, can be
    # seen only as a direct child of {Template}.
    class Var < Compound
      attr_reader :name

      def initialize(name, children = Nodes[])
        super(children)
        @name = name
      end

      # Internal, used by {Parser}
      def empty?
        false
      end

      protected

      def descr
        "#{clean_class}(#{name})"
      end

      def _eq(other)
        other.name == name && other.children == children
      end
    end

    # Wikipedia template.
    #
    # Templates are complicated! Also, they are useful.
    #
    # You'd need to understand them from [Wikipedia docs](https://en.wikipedia.org/wiki/Wikipedia:Templates)
    # and then use much of Infoboxer's goodness provided with {Templates}
    # separate module.
    class Template < Compound
      attr_reader :name, :variables

      def initialize(name, variables = Nodes[])
        super(Nodes[], extract_params(variables))
        @name  = name 
        @variables = Nodes[*variables].each{|v| v.parent = self}
      end

      # See {Node#to_tree}
      def to_tree(level = 0)
        '  ' * level + "<#{descr}>\n" +
          variables.map{|var| var.to_tree(level+1)}.join
      end

      def fetch(*patterns)
        Nodes[*patterns.map{|p| variables.find(name: p)}.flatten]
      end

      def fetch_hash(*patterns)
        fetch(*patterns).map{|v| [v.name, v]}.to_h
      end

      def fetch_date(*patterns)
        components = fetch(*patterns)
        components.pop while components.last.nil? && !components.empty?
        
        if components.empty?
          nil
        else
          Date.new(*components.map{|v| v.to_s.to_i})
        end
      end

      # Internal, used by {Parser}.
      def empty?
        false
      end

      protected

      def _eq(other)
        other.name == name && other.variables == variables
      end

      def clean_class
        "Template[#{name}]"
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
