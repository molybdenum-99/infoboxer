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

      class << self
        attr_accessor :template_name, :template_options

        def inspect
          "#<#{clean_name}>"
        end

        def clean_name
          name ? name.sub(/^.*::/, '') : "Template[#{template_name}]"
        end
      end

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

    class InFlowTemplate < Template
      class << self
        def clean_name
          name ? name.sub(/^.*::/, '') : "InFlowTemplate[#{template_name}]"
        end
      end
      
      def initialize(name, variables = Nodes.new)
        super
        @children = unnamed_variables
      end

      def text
        children.map(&:text).join(separator)
      end

      def separator
        ' '
      end

      def unnamed_variables
        variables.select{|v| v.name =~ /^\d+$/}
      end
    end
  end
end
