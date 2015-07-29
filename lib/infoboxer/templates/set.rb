# encoding: utf-8
module Infoboxer
  module Templates
    class Set
      def initialize(&definitions)
        @templates = []
        define(&definitions) if definitions
      end
      
      def find(name)
        _, template = @templates.detect{|m, t| m === name.downcase}
        template || Base
      end

      def define(&definitions)
        instance_eval(&definitions)
      end

      def clear
        @templates.clear
      end

      private

      def template(name, options = {}, &definition)
        setup_class(name, Base, options, &definition)
      end

      def replace(*replacements)
        case
        when replacements.count == 2 && replacements.all?{|r| r.is_a?(String)}
          name, what = *replacements
          setup_class(name, Replace) do
            define_method(:replace) do
              what
            end
          end
        when replacements.count == 1 && replacements.first.is_a?(Hash)
          replacements.first.each do |name, what|
            replace(name, what)
          end
        else
          fail(ArgumentError, "Can't call :replace with #{replacements.join(', ')}")
        end
      end

      def show(*names)
        names.each do |name|
          setup_class(name, Show)
        end
      end

      def literal(*names)
        names.each do |name|
          setup_class(name, Literal)
        end
      end

      def setup_class(name, base_class, options = {}, &definition)
        match = options.fetch(:match, name.downcase)
        base = options.fetch(:base, base_class)
        base = self.find(base) if base.is_a?(String)

        Class.new(base, &definition).tap{|cls|
          cls.template_name = name
          cls.template_options = options
          @templates.unshift [match, cls]
        }
      end
    end
  end
end
