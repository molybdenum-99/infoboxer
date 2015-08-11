# encoding: utf-8
module Infoboxer
  class MediaWiki
    # DSL for defining "traits" for some site.
    #
    # More docs (and possible refactoring) to follow.
    #
    # You can look at current
    # [English Wikipedia traits](https://github.com/molybdenum-99/infoboxer/blob/master/lib/infoboxer/definitions/en.wikipedia.org.rb)
    # definitions in Infoboxer's repo.
    class Traits
      class << self
        # Define set of templates for current site's traits.
        #
        # See {Templates::Set} for longer (yet insufficient) explanation.
        #
        # Expected to be used inside Traits definition block.
        def templates(&definition)
          @templates ||= Templates::Set.new

          return @templates unless definition
          
          @templates.define(&definition)
        end

        # @private
        def domain(d)
          # NB: explicitly store all domains in base Traits class
          Traits.domains.key?(d) and
            fail(ArgumentError, "Domain binding redefinition: #{Traits.domains[d]}")

          Traits.domains[d] = self
        end

        # @private
        def get(domain, options = {})
          cls = Traits.domains[domain]
          cls ? cls.new(options) : Traits.new(options)
        end

        # @private
        def domains
          @domains ||= {}
        end

        # Define traits for some  domain. Use it like:
        #
        # ```ruby
        # MediaWiki::Traits.for 'ru.wikipedia.org' do
        #   templates do
        #     template '...' do
        #       # some template definition
        #     end
        #   end
        # end
        # ```
        #
        # Again, you can look at current
        # [English Wikipedia traits](https://github.com/molybdenum-99/infoboxer/blob/master/lib/infoboxer/definitions/en.wikipedia.org.rb)
        # for example implementation.
        def for(domain, &block)
          Class.new(self, &block).domain(domain)
        end

        # @private
        alias_method :default, :new
      end

      def initialize(options = {})
        @options = options
        @file_prefix = [DEFAULTS[:file_prefix], options.delete(:file_prefix)].
          flatten.compact.uniq
        @category_prefix = [DEFAULTS[:category_prefix], options.delete(:category_prefix)].
          flatten.compact.uniq
      end

      # @private
      attr_reader :file_prefix, :category_prefix

      # @private
      def templates
        self.class.templates
      end

      private

      DEFAULTS = {
        file_prefix: 'File',
        category_prefix: 'Category'
      }

    end
  end
end
