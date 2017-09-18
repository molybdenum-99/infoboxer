# encoding: utf-8

module Infoboxer
  module Navigation
    # `Sections` module provides logical view on document strcture.
    #
    # From this module's point of view, each {Tree::Document Document} is a
    # {Sections::Container Sections::Container}, which consists of
    # {Sections::Container#intro} (before first heading) and a set of
    # nested {Sections::Container#sections}.
    #
    # Each document node, in turn, provides method {Sections::Node#in_sections},
    # allowing you to receive list of sections, which contains current
    # node.
    #
    # **NB**: Sections are "virtual" nodes, they are not, in fact, in
    # documents tree. So, you can be surprised with:
    #
    # ```ruby
    # document.sections         # => list of Section instances
    # document.lookup(:Section) # => []
    #
    # paragraph.in_sections     # => list of sections
    # paragraph.
    #  lookup_parents(:Section) # => []
    # ```
    module Sections
      # This module is included in {Tree::Document Document}, allowing
      # you to navigate through document's logical sections (and also
      # included in each {Sections::Section} instance, allowing to navigate
      # recursively).
      #
      # See also {Sections parent module} docs.
      module Container
        # All container's paragraph-level nodes before first heading.
        #
        # @return {Tree::Nodes}
        def intro
          children
            .take_while { |n| !n.is_a?(Tree::Heading) }
            .select { |n| n.is_a?(Tree::BaseParagraph) }
        end

        # List of sections inside current container.
        #
        # Examples of usage:
        #
        # ```ruby
        # document.sections                 # all top-level sections
        # document.sections('Culture')      # only "Culture" section
        # document.sections(/^List of/)     # all sections with heading matching pattern
        #
        # document.
        #   sections('Culture').            # long way of recieve nested section
        #     sections('Music')             # (Culture / Music)
        #
        # document.
        #   sections('Culture', 'Music')    # the same as above
        #
        # document.
        #   sections('Culture' => 'Music')  # pretty-looking version for 2 levels of nesting
        # ```
        #
        # @return {Tree::Nodes<Section>}
        def sections(*names)
          @sections ||= make_sections

          if names.first.is_a?(Hash)
            h = names.shift
            h.count == 1 or fail(ArgumentError, "Undefined behavior with #{h}")
            names.unshift(h.keys.first, h.values.first)
          end

          case names.count
          when 0
            @sections
          when 1
            @sections.select { |s| names.first === s.heading.text_ }
          else
            @sections.select { |s| names.first === s.heading.text_ }.sections(*names[1..-1])
          end
        end

        def subsections(*names)
          sections = names.map { |name|
            heading = lookup_children(:Heading, text_: name).first
            next unless heading
            body = heading.next_siblings
                          .take_while { |n| !n.is_a?(Tree::Heading) || n.level > heading.level }

            Section.new(heading, body)
          }.compact
          Tree::Nodes.new(sections)
        end

        def lookup_children(*arg)
          if arg.include?(:Section)
            sections.find(*(arg - [:Section]))
          else
            super
          end
        end

        private

        def make_sections
          res = Tree::Nodes[]
          return res if headings.empty?
          level = headings.first.level

          children
            .chunk { |n| n.matches?(Tree::Heading, level: level) }
            .drop_while { |is_heading, _nodes| !is_heading }
            .each do |is_heading, nodes|
              if is_heading
                nodes.each do |node|
                  res << Section.new(node)
                end
              else
                res.last.push_children(*nodes)
              end
            end

          res
        end
      end

      # Part of {Sections} navigation, allowing each node to know exact
      # list of sections it contained in.
      #
      # See also {Sections parent module} documentation.
      module Node
        # List of sections current node contained in (bottom-to-top:
        # smallest section first).
        #
        # @return {Tree::Nodes<Section>}
        def in_sections
          return parent.in_sections unless parent.is_a?(Tree::Document)
          return @in_sections if @in_sections

          heading =
            if is_a?(Tree::Heading)
              lookup_prev_sibling(Tree::Heading, level: level - 1)
            else
              lookup_prev_sibling(Tree::Heading)
            end
          unless heading
            @in_sections = Tree::Nodes[]
            return @in_sections
          end

          body = heading.next_siblings
                        .take_while { |n| !n.is_a?(Tree::Heading) || n.level > heading.level }

          section = Section.new(heading, body)
          @in_sections = Tree::Nodes[section, *heading.in_sections]
        end
      end

      # Part of {Sections} navigation, allowing chains of section search.
      #
      # See {Sections parent module} documentation.
      module Nodes
        # @!method sections(*names)
        # @!method in_sections

        %i[sections in_sections].each do |sym|
          define_method(sym) do |*args|
            make_nodes(map { |n| n.send(sym, *args) })
          end
        end

        def lookup_children(*arg)
          if arg.include?(:Section)
            sections.find(*(arg - [:Section]))
          else
            super
          end
        end
      end

      # Virtual node, representing logical section of the document.
      # Is not, in fact, in the tree.
      #
      # See {Sections parent module} documentation for details.
      class Section < Tree::Compound
        def initialize(heading, children = Tree::Nodes[])
          # no super: we don't wont to rewrite children's parent
          @children = Tree::Nodes[*children]
          @heading = heading
          @params = {level: heading.level, heading: heading.text.strip}
        end

        # Section's heading.
        #
        # @return {Tree::Heading}
        attr_reader :heading

        # no rewriting of parent, again
        def push_children(*nodes)
          nodes.each do |n|
            @children << n
          end
        end

        def empty?
          false
        end

        def inspect
          "#<#{descr}: #{children.count} nodes>"
        end

        include Container
      end
    end
  end
end
