# encoding: utf-8
module Infoboxer
  class MediaWiki
    class Context
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
            template(name){|t| t.variables[1]}
          end
        end

        def selectors
          @selectors ||= {}
        end

        def templates
          @templates ||= {}
        end
      end

      def selector(descriptor)
        self.class.selectors[descriptor] or
          fail(ArgumentError, "Descriptor #{descriptor} not defined for #{self}")
      end

      def lookup(descriptor, node)
        node._lookup(selector(descriptor))
      end

      def substitute(template)
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
