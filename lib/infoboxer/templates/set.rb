# frozen_string_literal: true

module Infoboxer
  module Templates
    # Base class for defining set of templates, used for some site/domain.
    #
    # Currently only can be plugged in via {MediaWiki::Traits.templates}.
    #
    # Template set defines a DSL for creating new template definitions --
    # also simplest ones and very complicated.
    #
    # You can look at implementation of English Wikipedia
    # [common templates set](https://github.com/molybdenum-99/infoboxer/blob/master/lib/infoboxer/definitions/en.wikipedia.org.rb)
    # in Infoboxer's repo.
    #
    class Set
      def initialize(&definitions)
        @templates = []
        define(&definitions) if definitions
      end

      # @private
      def find(name)
        _, template = @templates.detect { |m, _t| m === name.downcase }
        template || Base
      end

      # @private
      def define(&definitions)
        instance_eval(&definitions)
      end

      # @private
      def clear
        @templates.clear
      end

      # Most common form of template definition.
      #
      # Can be used like:
      #
      # ```ruby
      # template 'Age' do
      #   def from
      #     fetch_date('1', '2', '3')
      #   end
      #
      #   def to
      #     fetch_date('4', '5', '6') || Date.today
      #   end
      #
      #   def value
      #     (to - from).to_i / 365 # FIXME: obviously
      #   end
      #
      #   def text
      #     "#{value} years"
      #   end
      # end
      # ```
      #
      # @param name Definition name.
      # @param options Definition options.
      #   Currently recognized options are:
      #   * `:match` -- regexp or string, which matches template name to
      #     add this definition to (if not provided, `name` param used
      #     to match relevant templates);
      #   * `:base` -- name of template definition to use as a base class;
      #     for example you can do things like:
      #
      #   ```ruby
      #   # ...inside template set definition...
      #   template 'Infobox', match: /^Infobox/ do
      #     # implementation
      #   end
      #
      #   template 'Infobox cheese', base: 'Infobox' do
      #   end
      #   ```
      #
      # Expected to be used inside Set definition block.
      def template(name, options = {}, &definition)
        setup_class(name, Base, options, &definition)
      end

      # Define list of "replacements": templates, which text should be replaced
      # with arbitrary value.
      #
      # Example:
      #
      # ```ruby
      # # ...inside template set definition...
      # replace(
      #   '!!' => '||',
      #   '!(' => '['
      # )
      # ```
      # Now, all templates with name `!!` will render as `||` when you
      # call their (or their parents') {Tree::Node#text}.
      #
      # Expected to be used inside Set definition block.
      def replace(*replacements)
        case
        when replacements.count == 2 && replacements.all? { |r| r.is_a?(String) }
          name, what = *replacements
          setup_class(name, Replace) do
            define_method(:replace) do
              what
            end
          end
        when replacements.count == 1 && replacements.first.is_a?(Hash)
          replacements.first.each do |nm, rep|
            replace(nm, rep)
          end
        else
          fail(ArgumentError, "Can't call :replace with #{replacements.join(', ')}")
        end
      end

      # Define list of "show children" templates. Those ones, when rendered
      # as text, just provide join of their children text (space-separated).
      #
      # Example:
      #
      # ```ruby
      # #...in template set definition...
      # show 'Small'
      # ```
      # Now, wikitext paragraph looking like...
      #
      # ```
      # This is {{small|text}} in template
      # ```
      # ...before this template definition had rendered like
      # `"This is  in template"` (template contents ommitted), and after
      # this definition it will render like `"This is text in template"`
      # (template contents rendered as is).
      #
      # Expected to be used inside Set definition block.
      def show(*names)
        names.each do |name|
          setup_class(name, Show)
        end
      end

      # Define list of "literally rendered templates". It means, when
      # rendering text, template is replaced with just its name.
      #
      # Explanation: in
      # MediaWiki, there are contexts (deeply in other templates and
      # tables), when you can't just type something like `","` and not
      # have it interpreted. So, wikis oftenly define wrappers around
      # those templates, looking like `{{,}}` -- so, while rendering texts,
      # such templates can be replaced with their names.
      #
      # Expected to be used inside Set definition block.
      def literal(*names)
        names.each do |name|
          setup_class(name, Literal)
        end
      end

      # @private
      def setup_class(name, base_class, options = {}, &definition)
        match = options.fetch(:match, name.downcase)
        base = options.fetch(:base, base_class)
        base = find(base) if base.is_a?(String)

        Class.new(base, &definition).tap do |cls|
          cls.template_name = name
          cls.template_options = options
          @templates.unshift [match, cls]
        end
      end
    end
  end
end
