# encoding: utf-8
module Infoboxer
  module SemanticNavigation
    def wikilinks(namespace = '')
      lookup(Wikilink, namespace: namespace)
    end

    def headings(level = nil)
      lookup(Heading, level: level)
    end

    def paragraphs(*args, &block)
      lookup(BaseParagraph, *args, &block)
    end

    def external_links(*args, &block)
      lookup(ExternalLink, *args, &block)
    end

    def images(*args, &block)
      lookup(Image, *args, &block)
    end

    def templates(*args, &block)
      lookup(Template, *args, &block)
    end

    def tables(*args, &block)
      lookup(Table, *args, &block)
    end

    def lists(*args, &block)
      lookup(List, *args, &block)
    end

    def bold?
      has_parent?(Bold)
    end

    def italic?
      has_parent?(Italic)
    end

    def heading?(level = nil)
      has_parent?(Heading, level: level)
    end

    def infoboxes(*args, &block)
      lookup(Template, :infobox?, *args, &block)
    end

    # As users accustomed to have only one infobox on a page
    alias_method :infobox, :infoboxes
  end

  module SectionsNavigation
    def intro
      children.
        take_while{|n| !n.is_a?(Heading)}.
        select{|n| n.is_a?(BaseParagraph)}
    end

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
        @sections.select{|s| names.first === s.heading.text_}
      else
        @sections.select{|s| names.first === s.heading.text_}.sections(*names[1..-1])
      end
    end

    private

    def make_sections
      res = Nodes[]
      return res if headings.empty?
      level = headings.first.level

      children.
        chunk{|n| n.matches?(Heading, level: level)}.
        drop_while{|is_heading, nodes| !is_heading}.
        each do |is_heading, nodes|
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

  module InSectionsNavigation
    def in_sections
      heading = if is_a?(Heading)
        lookup_prev_siblings(Heading, level: level - 1).last
      else
        lookup_prev_siblings(Heading).last
      end
      return [] unless heading
      
      section = Section.new(heading,
        heading.next_siblings.take_while{|n| !n.is_a?(Heading) || n.level < heading.level}
      )
      Nodes[section, *heading.in_sections]
    end
  end
end
