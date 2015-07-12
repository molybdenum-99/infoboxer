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
      @name, @variables = name, Nodes[*variables]
    end

    def _eq(other)
      other.name == name && other.variables == variables
    end

    def clean_class
      self.class.clean_name
    end

    def inspect(depth = 0)
      if depth.zero? && !variables.empty?
        "#<#{descr}: #{variables.inspect_no_p(depth)}>"
      else
        "#<#{descr}>"
      end
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
      Date.new(*fetch(*patterns).map{|v| v.to_s.to_i})
    end

    def empty?
      false
    end

    protected
      def descr
        self.class.template_name == name ? clean_class : "#{clean_class}(#{name})"
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

    def to_text
      children.map(&:to_text).join(separator)
    end

    def separator
      ' '
    end

    def unnamed_variables
      variables.select{|v| v.name =~ /^\d+$/}
    end
  end
end
