# encoding: utf-8
require 'procme'
require 'infoboxer/core_ext'

require_relative 'parser/node'

module Infoboxer
  class Parser
    class ParseError < Exception
    end
    
    class Document < Compound
    end

    class Nodes < Array
      MAX_CHILDREN = 3
      
      def inspect
        if count > MAX_CHILDREN
          '[' + self[0...MAX_CHILDREN].map(&:inspect).join(', ') + " ...#{count - MAX_CHILDREN} more]"
        else
          super
        end
      end
    end

    def self.parse(text)
      new(text).parse
    end

    def initialize(text)
      @lines = text.split(/\r?\n/m)
      @nodes = Nodes.new
    end

    def parse
      until @lines.empty?
        current = @lines.shift

        case current
        when /^={2,}/
          heading(current)
        when /^\s*{\|/
          @lines.unshift(current)
          table # it will parse lines, including current
        when /^[\*\#:;]./
          list(current)
        when /^-{4,}/
          node(HR)
        when /^ /
          pre(current)
        when '' # blank line = space between paragraphs/lists
          @nodes.empty? or @nodes.last.closed!
        else
          para(current)
        end
      end

      merge_nodes!

      Document.new(@nodes)
    end

    def parse_inline
      InlineParser.new(@lines.join("\n")).parse
    end

    private

    # Paragraph-level nodes DSL ----------------------------------------
    def para(str)
      node(Paragraph, inline(str))
    end

    def heading(str)
      level, text = str.scan(/^(={2,})\s*(.+?)(?:\s*=+)?$/).flatten
      node(Heading, inline(text), level.length)
    end

    # TODO: list type
    def list(str)
      marker, text = str.scan(/^([*\#:;]+)\s*(.+?)$/).flatten
      node(ListItem, inline(text), marker)
    end

    def pre(str)
      node(Pre, [Parser::Text.new(str.sub(/^ /, ''))])
    end

    def table
      @nodes << TableParser.parse(@lines)
    end

    # Post-processing --------------------------------------------------
    def merge_nodes!
      return if @nodes.count < 2
      
      merged = [@nodes.first]

      @nodes[1..-1].each do |node|
        if merged.last.can_merge?(node)
          merged.last.merge!(node)
        else
          merged << node
        end
      end

      @nodes.replace(merged)
    end

    # Basic internals --------------------------------------------------
    def inline(str)
      InlineParser.new(str, @lines).parse
    end
    
    def node(klass, *arg)
      @nodes << klass.new(*arg)
    end
  end
end

require_relative 'parser/commons'
require_relative 'parser/inline'
require_relative 'parser/table'
