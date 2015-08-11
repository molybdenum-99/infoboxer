module Infoboxer
  module Templates
    class Base < Tree::Template
      include Tree
      
      class << self
        attr_accessor :template_name, :template_options

        def inspect
          template_name ? "Infoboxer::Templates::#{clean_name}" : super
        end

        def clean_name
          template_name ? "Template[#{template_name}]" : 'Template'
        end
      end

      def ==(other)
        other.kind_of?(Tree::Template) && _eq(other)
      end

      protected

      def clean_class
        if self.class.template_name == name
          self.class.clean_name
        else
          super
        end
      end
    end

    # Renders all of its unnamed variables as space-separated text
    # Also allows in-template navigation.
    #
    # Used for {Set} definitions.
    class Show < Base
      alias_method :children, :unnamed_variables

      protected

      def children_separator
        ' '
      end
    end

    # Replaces template with replacement, while rendering.
    #
    # Used for {Set} definitions.
    class Replace < Base
      def replace
        fail(NotImplementedError, "Descendants should define :replace")
      end

      def text
        replace
      end
    end

    # Replaces template with its name, while rendering.
    #
    # Used for {Set} definitions.
    class Literal < Base
      alias_method :text, :name
    end
  end
end
