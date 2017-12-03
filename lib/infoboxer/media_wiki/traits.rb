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
        def get(domain, site_info = {})
          (Traits.domains[domain] || Traits).new(site_info)
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
          Traits.domains[domain].tap { |c| c && c.instance_eval(&block) } ||
            Class.new(self, &block).domain(domain)
        end

        # @private
        alias_method :default, :new
      end

      def initialize(site_info = {})
        @site_info = site_info
      end

      def namespace?(prefix)
        known_namespaces.include?(prefix)
      end

      def interwiki?(prefix)
        known_interwikis.key?(prefix)
      end

      # @private
      def file_namespace
        @file_namespace ||= ns_aliases('File')
      end

      # @private
      def category_namespace
        @category_namespace ||= ns_aliases('Category')
      end

      # @private
      def templates
        self.class.templates
      end

      private

      def known_namespaces
        @known_namespaces ||=
          if @site_info.empty?
            STANDARD_NAMESPACES
          else
            (@site_info['namespaces'].values + @site_info['namespacealiases']).map { |n| n['*'] }
          end
      end

      def known_interwikis
        @known_interwikis ||=
          if @site_info.empty?
            {}
          else
            @site_info['interwikimap'].map { |iw| [iw['prefix'], iw] }.to_h
          end
      end

      def ns_aliases(base)
        return [base] if @site_info.empty?
        main = @site_info['namespaces'].values.detect { |n| n['canonical'] == base }
        [base, main['*']] +
          @site_info['namespacealiases']
          .select { |a| a['id'] == main['id'] }.flat_map { |n| n['*'] }
          .compact.uniq
      end

      # See https://www.mediawiki.org/wiki/Help:Namespaces#Standard_namespaces
      STANDARD_NAMESPACES = [
        'Media',            # Direct linking to media files.
        'Special',          # Special (non-editable) pages.
        '',                 # (Main)
        'Talk',             # Article discussion.
        'User',             #
        'User talk',        #
        'Project',          # Meta-discussions related to the operation and development of the wiki.
        'Project talk',     #
        'File',             # Metadata for images, videos, sound files and other media.
        'File talk',        #
        'MediaWiki',        # System messages and other important content.
        'MediaWiki talk',   #
        'Template',         # Templates: blocks of text or wikicode that are intended to be transcluded.
        'Template talk',    #
        'Help',             # Help files, instructions and "how-to" guides.
        'Help talk',        #
        'Category',         # Categories: dynamic lists of other pages.
        'Category talk',    #
      ].freeze
    end
  end
end
