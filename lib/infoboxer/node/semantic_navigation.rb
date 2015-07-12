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
      level = headings.first.level
      res = Nodes[]

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
end
