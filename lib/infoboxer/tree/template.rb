# encoding: utf-8
require_relative 'linkable'

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

    # Represents MediaWiki **template**.
    #
    # [**Template**](https://en.wikipedia.org/wiki/Wikipedia:Templates)
    # is basically a thing with name, some variables and their
    # values. When pages are displayed in browser, templates are rendered in
    # something different by wiki engine; yet, when extracting information
    # with Infoboxer, you are working with original templates.
    #
    # It requires some mastering and understanding, yet allows to do
    # very poweful things. There are many kinds of them, from pure
    # formatting-related (which are typically not more than small bells
    # and whistles for page outlook, and should be rendered as a text)
    # to very information-heavy ones, like
    # [**infoboxes**](https://en.wikipedia.org/wiki/Help:Infobox), from
    # which Infoboxer borrows its name!
    #
    # Basically, for information extraction from template you'll list
    # its {#variables}, and then use {#fetch} method
    # (and its variants: {#fetch_hash}/#{fetch_date}) to extract their
    # values.
    #
    # ### On variables naming
    # MediaWiki templates can contain _named_ and _unnamed_ variables.
    # Example:
    #
    # ```
    # {{birth date and age|1953|2|19|df=y}}
    # ```
    #
    # This is template with name "birth date and age", three unnamed
    # variables with values "1953", "2" and "19", and one named variable
    # with name "df" and value "y".
    #
    # For consistency, Infoboxer treats unnamed variables _exactly_ the
    # same way MediaWiki does: they considered to have numeric names,
    # which are _started from 1_ and _stored as a strings_. So, for
    # template shown above, the following is correct:
    #
    # ```ruby
    # template.fetch('1').text == '1953'
    # template.fetch('2').text == '2'
    # template.fetch('3').text == '19'
    # template.fetch('df').text == 'y'
    # ```
    #
    # Note also, that _named variables with simple text values_ are
    # duplicated as a template node {Node#params}, so, the following is
    # correct also:
    #
    # ```ruby
    # template.params['df'] == 'y'
    # template.params.has_key?('1') == false
    # ```
    #
    # For more advanced topics, like subclassing templates by names and
    # converting them to inline text, please read {Templates} module's
    # documentation.
    class Template < Compound
      # Template name, designating its contents structure.
      #
      # See also {Linkable#url #url}, which you can navigate to read template's
      # definition (and, in Wikipedia and many other projects, its
      # documentation).
      #
      # @return [String]
      attr_reader :name

      # Template variables list.
      #
      # See {Var} class to understand what you can do with them.
      #
      # @return [Nodes<Var>]
      attr_reader :variables

      def initialize(name, variables = Nodes[])
        super(Nodes[], extract_params(variables))
        @name = name
        @variables = Nodes[*variables].each { |v| v.parent = self }
      end

      # See {Node#to_tree}
      def to_tree(level = 0)
        '  ' * level + "<#{descr}>\n" +
          variables.map { |var| var.to_tree(level + 1) }.join
      end

      # Represents entire template as hash of `String => String`,
      # where keys are variable names and values are text representation
      # of variables contents.
      #
      # @return [Hash{String => String}]
      def to_h
        variables.map { |var| [var.name, var.text] }.to_h
      end

      # Returns list of template variables with numeric names (which
      # are treated as "unnamed" variables by MediaWiki templates, see
      # {Template class docs} for explanation).
      #
      # @return [Nodes<Var>]
      def unnamed_variables
        variables.find(name: /^\d+$/)
      end

      # Fetches template variable(s) by name(s) or patterns.
      #
      # Usage:
      #
      # ```ruby
      # argentina.infobox.fetch('leader_title_1')   # => one Var node
      # argentina.infobox.fetch('leader_title_1',
      #                         'leader_name_1')    # => two Var nodes
      # argentina.infobox.fetch(/leader_title_\d+/) # => several Var nodes
      # ```
      #
      # @return [Nodes<Var>]
      def fetch(*patterns)
        Nodes[*patterns.map { |p| variables.find(name: p) }.flatten]
      end

      # Fetches hash `{name => variable}`, by same patterns as {#fetch}.
      #
      # @return [Hash<String => Var>]
      def fetch_hash(*patterns)
        fetch(*patterns).map { |v| [v.name, v] }.to_h
      end

      # Fetches date by list of variable names containing date components.
      #
      # _(Experimental, subject to change or enchance.)_
      #
      # Explanation: if you have template like
      # ```
      # {{birth date and age|1953|2|19|df=y}}
      # ```
      # ...there is a short way to obtain date from it:
      # ```ruby
      # template.fetch_date('1', '2', '3') # => Date.new(1953,2,19)
      # ```
      #
      # @return [Date]
      def fetch_date(*patterns)
        components = fetch(*patterns)
        components.pop while components.last.nil? && !components.empty?

        if components.empty?
          nil
        else
          Date.new(*components.map { |v| v.to_s.to_i })
        end
      end

      include Linkable

      # @!method follow
      # Extracts template source and returns it parsed (or nil,
      # if template not found).
      #
      # **NB**: Infoboxer does NO variable substitution or other template
      # evaluation actions. Moreover, it will almost certainly NOT parse
      # template definitions correctly. You should use this method ONLY
      # for "transclusion" templates (parts of content, which are
      # included into other pages "as is").
      #
      # Look for example at [this page's](https://en.wikipedia.org/wiki/Tropical_and_subtropical_coniferous_forests)
      # [source](https://en.wikipedia.org/w/index.php?title=Tropical_and_subtropical_coniferous_forests&action=edit):
      # each subtable about some region is just a transclusion of
      # template. This can be processed like:
      #
      # ```ruby
      # Infoboxer.wp.get('Tropical and subtropical coniferous forests').
      #   templates(name: /forests^/).
      #   follow.tables #.and_so_on
      # ```
      #
      # @return {MediaWiki::Page}
      #
      # **See also** {Linkable#follow} for general notes on the following links.

      # Wikilink name of this template's source.
      def link
        # FIXME: super-naive for now, doesn't thinks about subpages and stuff.
        "Template:#{name}"
      end

      # @private
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
        vars
          .select { |v| v.children.count == 1 && v.children.first.is_a?(Text) }
          .map { |v| [v.name, v.children.first.raw_text] }.to_h
      end

      def inspect_variables(depth)
        variables.to_a[0..1].map { |name, var| "#{name}: #{var.inspect(depth + 1)}" }.join(', ') +
          (variables.count > 2 ? ', ...' : '')
      end
    end
  end
end
