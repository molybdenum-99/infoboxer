# encoding: utf-8
module Infoboxer
  class MediaWiki
    class Traits
      class << self
        def templates(&definition)
          @templates ||= TemplateSet.new

          return @templates unless definition
          
          @templates.define(&definition)
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

        def for(domain, &block)
          Class.new(self, &block).domain(domain)
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

      #attr_accessor :re

      def templates
        self.class.templates
      end
    end
  end
end
