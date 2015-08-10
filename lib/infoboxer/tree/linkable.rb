module Infoboxer
  module Tree
    # Module included into everything, that can be treated as
    # link to some MediaWiki page, despite of behavior. Namely,
    # {Wikilink} and {Template}.
    module Linkable
      # Extracts wiki page by this link and returns it parsed (or nil,
      # if page not found).
      #
      # About template "following" see also {Template#follow} docs.
      #
      # @return {MediaWiki::Page}
      #
      # **See also**:
      # * {Tree::Nodes#follow} for extracting multiple links at once;
      # * {MediaWiki#get} for basic information on page extraction.
      def follow
        client.get(link)
      end

      # Human-readable page URL
      #
      # @return [String]
      def url
        # FIXME: fragile as hell.
        page.url.sub(/[^\/]+$/, link.gsub(' ', '_'))
      end

      protected

      def page
        page = lookup_parents(MediaWiki::Page).first or
          fail("Not in a page from real source")
      end

      def client
        page.client or fail("MediaWiki client not set")
      end

    end
  end
end
