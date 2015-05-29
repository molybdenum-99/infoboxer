# encoding: utf-8
module Infoboxer
  module SemanticNavigation
    def wikilinks(namespace = '')
      lookup(Wikilink, namespace: namespace)
    end

    def headings(level = nil)
      lookup(Heading, level: level)
    end

    def paragraphs
      lookup(BaseParagraph)
    end

    def external_links
      lookup(ExternalLink)
    end

    def images
      lookup(Image)
    end

    def templates
      lookup(Template)
    end

    def tables
      lookup(Table)
    end
  end

  module SectionsNavigation
    def intro
      children.
        take_while{|n| !n.is_a?(Heading)}.
        select{|n| n.is_a?(BaseParagraph)}
    end

    def sections
      first_heading = headings.first
      sections = []

      children.
        chunk{|n| n.matches?(Heading, level: first_heading.level)}.
        drop_while{|is_heading, nodes| !is_heading}.
        each do |is_heading, nodes|
          if is_heading
            nodes.each do |node|
              sections << Section.new(node)
            end
          else
            sections.last.push_children(*nodes)
          end
        end

      sections
    end
  end
end
