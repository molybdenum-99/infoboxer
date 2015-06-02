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

        def selectors
          @selectors ||= {}
        end
      end

      def selector(descriptor)
        self.class.selectors[descriptor] or
          fail(ArgumentError, "Descriptor #{descriptor} not defined for #{self}")
      end

      def lookup(descriptor, node)
        node._lookup(selector(descriptor))
      end
    end
  end
end
