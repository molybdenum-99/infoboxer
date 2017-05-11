# encoding: utf-8

require 'mediawiktory'
require 'addressable/uri'

require_relative 'media_wiki/traits'
require_relative 'media_wiki/page'

module Infoboxer
  # MediaWiki client class.
  #
  # Usage:
  #
  # ```ruby
  # client = Infoboxer::MediaWiki
  #   .new('http://en.wikipedia.org/w/api.php', user_agent: 'My Own Project')
  # page = client.get('Argentina')
  # ```
  #
  # Consider using shortcuts like {Infoboxer.wiki}, {Infoboxer.wikipedia},
  # {Infoboxer.wp} and so on instead of direct instation of this class
  # (although you can if you want to!)
  #
  class MediaWiki
    # Default Infoboxer User-Agent header.
    #
    # You can set yours as an option to {Infoboxer.wiki} and its shortcuts,
    # or to {#initialize}
    UA = "Infoboxer/#{Infoboxer::VERSION} "\
      '(https://github.com/molybdenum-99/infoboxer; zverok.offline@gmail.com)'.freeze

    class << self
      # User agent getter/setter.
      #
      # Default value is {UA}.
      #
      # You can also use per-instance option, see {#initialize}
      #
      # @return [String]
      attr_accessor :user_agent
    end

    # @private
    attr_reader :api_base_url, :traits

    # Creating new MediaWiki client. {Infoboxer.wiki} provides shortcut
    # for it, as well as shortcuts for some well-known wikis, like
    # {Infoboxer.wikipedia}.
    #
    # @param api_base_url URL of `api.php` file in your MediaWiki
    #   installation. Typically, its `<domain>/w/api.php`, but can vary
    #   in different wikis.
    # @param options Only one option is currently supported:
    #   * `:user_agent` (also aliased as `:ua`) -- custom User-Agent header.
    def initialize(api_base_url, options = {})
      @api_base_url = Addressable::URI.parse(api_base_url)
      @client = MediaWiktory::Wikipedia::Api.new(api_base_url, user_agent: user_agent(options))
      @traits = Traits.get(@api_base_url.host, namespaces: extract_namespaces)
    end

    # Receive "raw" data from Wikipedia (without parsing or wrapping in
    # classes).
    #
    # @param titles [Array<String>] List of page titles to get.
    # @param prop [Array<Symbol>] List of additional page properties to get, refer to
    #   [MediaWiktory::Actions::Query#prop](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query#prop-instance_method)
    #   for the list of available properties.
    #
    # @return [Hash{String => Hash}] Hash of `{requested title => raw MediaWiki object}`. Note that
    #   even missing (does not exist in current Wiki) or invalid (impossible title) still be present
    #   in response, just will have `"missing"` or `"invalid"` key, just like MediaWiki returns them.
    def raw(*titles, prop: [])
      # could emerge on "automatically" created page lists, should work
      return {} if titles.empty?

      titles.each_slice(50).map do |part|
        response = @client
                   .query
                   .titles(*part)
                   .prop(:revisions, :info, *prop).prop(:content, :timestamp, :url)
                   .redirects
                   .response

        sources = response['pages'].values.map { |page| [page['title'], page] }.to_h
        redirects =
          if response['redirects']
            response['redirects'].map { |r| [r['from'], sources[r['to']]] }.to_h
          else
            {}
          end

        # This way for 'Einstein' query we'll have {'Albert Einstein' => page, 'Einstein' => same page}
        sources.merge(redirects)
      end.inject(:merge)
    end

    # Receive list of parsed MediaWiki pages for list of titles provided.
    # All pages are received with single query to MediaWiki API.
    #
    # **NB**: if you are requesting more than 50 titles at once
    # (MediaWiki limitation for single request), Infoboxer will do as
    # many queries as necessary to extract them all (it will be like
    # `(titles.count / 50.0).ceil` requests)
    #
    # @param titles [Array<String>] List of page titles to get.
    # @param prop [Array<Symbol>] List of additional page properties to get, refer to
    #   [MediaWiktory::Actions::Query#prop](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query#prop-instance_method)
    #   for the list of available properties.
    #
    # @return [Page, Tree::Nodes<Page>] array of parsed pages. Notes:
    #   * if you call `get` with only one title, one page will be
    #     returned instead of an array
    #   * if some of pages are not in wiki, they will not be returned,
    #     therefore resulting array can be shorter than titles array;
    #     you can always check `pages.map(&:title)` to see what you've
    #     really received; this approach allows you to write absent-minded
    #     code like this:
    #
    #     ```ruby
    #     Infoboxer.wp.get('Argentina', 'Chile', 'Something non-existing').
    #        infobox.fetch('some value')
    #     ```
    #     and obtain meaningful results instead of `NoMethodError` or
    #     `SomethingNotFound`.
    #
    def get(*titles, prop: [])
      pages = get_h(*titles, prop: prop).values.compact
      titles.count == 1 ? pages.first : Tree::Nodes[*pages]
    end

    # Same as {#get}, but returns hash of `{requested title => page}`.
    #
    # Useful quirks:
    # * when requested page not existing, key will be still present in
    #   resulting hash (value will be `nil`);
    # * when requested page redirects to another, key will still be the
    #   requested title. For ex., `get_h('Einstein')` will return hash
    #   with key 'Einstein' and page titled 'Albert Einstein'.
    #
    # This allows you to be in full control of what pages of large list
    # you've received.
    #
    # @param titles [Array<String>] List of page titles to get.
    # @param prop [Array<Symbol>] List of additional page properties to get, refer to
    #   [MediaWiktory::Actions::Query#prop](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query#prop-instance_method)
    #   for the list of available properties.
    #
    # @return [Hash<String, Page>]
    #
    def get_h(*titles, prop: [])
      raw_pages = raw(*titles, prop: prop)
                  .tap { |ps| ps.detect { |_, p| p['invalid'] }.tap { |_, i| i && fail(i['invalidreason']) } }
                  .reject { |_, p| p.key?('missing') }
      titles.map { |title| [title, make_page(raw_pages, title)] }.to_h
    end

    # Receive list of parsed MediaWiki pages from specified category.
    #
    # **NB**: currently, this API **always** fetches all pages from
    # category, there is no option to "take first 20 pages". Pages are
    # fetched in 50-page batches, then parsed. So, for large category
    # it can really take a while to fetch all pages.
    #
    # @param title [String] Category title. You can use namespaceless title (like
    #     `"Countries in South America"`), title with namespace (like
    #     `"Category:Countries in South America"`) or title with local
    #     namespace (like `"Catégorie:Argentine"` for French Wikipedia)
    #
    # @return [Tree::Nodes<Page>] array of parsed pages.
    #
    def category(title)
      title = normalize_category_title(title)

      list(@client.query.generator(:categorymembers).title(title).limit('max'))
    end

    # Receive list of parsed MediaWiki pages for provided search query.
    # See [MediaWiki API docs](https://www.mediawiki.org/w/api.php?action=help&modules=query%2Bsearch)
    # for details.
    #
    # **NB**: currently, this API **always** fetches all pages from
    # category, there is no option to "take first 20 pages". Pages are
    # fetched in 50-page batches, then parsed. So, for large search query
    # it can really take a while to fetch all pages.
    #
    # @param query [String] Search query. For old installations, look at
    #     https://www.mediawiki.org/wiki/Help:Searching
    #     for search syntax. For new ones (including Wikipedia), see at
    #     https://www.mediawiki.org/wiki/Help:CirrusSearch.
    #
    # @return [Tree::Nodes<Page>] array of parsed pages.
    #
    def search(query)
      list(@client.query.generator(:search).search(query).limit('max'))
    end

    # Receive list of parsed MediaWiki pages with titles startin from prefix.
    # See [MediaWiki API docs](https://www.mediawiki.org/w/api.php?action=help&modules=query%2Bprefixsearch)
    # for details.
    #
    # **NB**: currently, this API **always** fetches all pages from
    # category, there is no option to "take first 20 pages". Pages are
    # fetched in 50-page batches, then parsed. So, for large search query
    # it can really take a while to fetch all pages.
    #
    # @param prefix [String] Page title prefix.
    #
    # @return [Tree::Nodes<Page>] array of parsed pages.
    #
    def prefixsearch(prefix)
      list(@client.query.generator(:prefixsearch).search(prefix).limit('max'))
    end

    # @return [String]
    def inspect
      "#<#{self.class}(#{@api_base_url.host})>"
    end

    private

    def make_page(raw_pages, title)
      _, source = raw_pages.detect { |ptitle, _| ptitle.casecmp(title).zero? }
      source or return nil
      Page.new(self, Parser.paragraphs(source['revisions'].first['*'], traits), source)
    end

    def list(query)
      response = query
                 .prop(:revisions, :info)
                 .prop(:content, :timestamp, :url)
                 .redirects
                 .response

      response = response.continue while response.continue?

      return Tree::Nodes[] if response['pages'].nil?

      pages = response['pages']
              .values.select { |p| p['missing'].nil? }
              .map { |raw| Page.new(self, Parser.paragraphs(raw['revisions'].first['*'], traits), raw) }

      Tree::Nodes[*pages]
    end

    def normalize_category_title(title)
      # FIXME: shouldn't it go to MediaWiktory?..
      namespace, titl = title.include?(':') ? title.split(':', 2) : [nil, title]
      namespace, titl = nil, title unless traits.category_namespace.include?(namespace)

      namespace ||= traits.category_namespace.first
      [namespace, titl].join(':')
    end

    def user_agent(options)
      options[:user_agent] || options[:ua] || self.class.user_agent || UA
    end

    def extract_namespaces
      siteinfo = @client.query.meta(:siteinfo).prop(:namespaces, :namespacealiases).response
      siteinfo['namespaces'].map do |_, namespace|
        aliases =
          siteinfo['namespacealiases'].select { |a| a['id'] == namespace['id'] }.map { |a| a['*'] }
        namespace.merge('aliases' => aliases)
      end
    end
  end
end
