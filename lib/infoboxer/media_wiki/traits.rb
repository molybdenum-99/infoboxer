# encoding: utf-8
module Infoboxer
  class MediaWiki
    class Traits
      class << self
        def selector(descriptor, *args, &block)
          selectors.key?(descriptor) and
            fail(ArgumentError, "Descriptor redefinition: #{selectors[descriptor]}")

          selectors[descriptor] = Node::Selector.new(*args, &block)
        end

        def template(name, &action)
          templates.key?(name) and
            fail(ArgumentError, "Template redefinition: #{templates[name]}")

          templates[name] = action
        end

        def templates_text(pairs)
          pairs.each do |from, to|
            template(from){to}
          end
        end

        def templates_unwrap(*names)
          names.each do |name|
            template(name){|t| t.variables.first.children}
          end
        end

        def selectors
          @selectors ||= {}
        end

        def templates
          @templates ||= {}
        end

        # NB: explicitly store all domains in base Traits class
        def domain(d)
          Traits.domains.key?(d) and
            fail(ArgumentError, "Domain binding redefinition: #{Traits.domains[d]}")

          Traits.domains[d] = self
        end

        def get(domain, options = {})
          cls = Traits.domains[domain]
          cls ? cls.new(options) : Traits.new(options)
        end

        def domains
          @domains ||= {}
        end

        alias_method :default, :new
      end

      DEFAULTS = {
        file_prefix: 'File',
        category_prefix: 'Category'
      }

      def initialize(options = {})
        @options = options
        @file_prefix = [DEFAULTS[:file_prefix], options.delete(:file_prefix)].
          flatten.compact.uniq
        @category_prefix = [DEFAULTS[:category_prefix], options.delete(:category_prefix)].
          flatten.compact.uniq
      end

      attr_reader :file_prefix, :category_prefix

      attr_accessor :re

      def selector(descriptor)
        self.class.selectors[descriptor] or
          fail(ArgumentError, "Descriptor #{descriptor} not defined for #{self}")
      end

      def lookup(descriptor, node)
        node._lookup(selector(descriptor))
      end

      def expand(template)
        action = self.class.templates[template.name] or return template

        res = action.call(template)
        case res
        when Node
          res
        when Nodes
          res.flatten
        else
          Text.new(res.to_s)
        end
      end
    end
  end
end
