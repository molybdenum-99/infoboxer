# encoding: utf-8
module Infoboxer
  class Section < Tree::Compound
    def initialize(heading, children = Tree::Nodes[])
      # no super: we don't wont to rewriter children's parent
      @children = Nodes[*children]
      @heading = heading
    end

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
      main_node = parent.is_a?(Document) ? self : lookup_parents[-2]
      
      heading = if main_node.is_a?(Heading)
        main_node.lookup_prev_siblings(Heading, level: main_node.level - 1).last
      else
        main_node.lookup_prev_siblings(Heading).last
      end
      return Nodes[] unless heading
      
      section = Section.new(heading,
        heading.next_siblings.take_while{|n| !n.is_a?(Heading) || n.level < heading.level}
      )
      Nodes[section, *heading.in_sections]
    end
  end

  Document.send(:include, SectionsNavigation)
  Section.send(:include, SectionsNavigation)
  
  Tree::Node.send(:include, InSectionsNavigation)
end
