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

    # @return [MediaWiktory::Wikipedia::Client]
    attr_reader :api

    # Creating new MediaWiki client. {Infoboxer.wiki} provides shortcut
    # for it, as well as shortcuts for some well-known wikis, like
    # {Infoboxer.wikipedia}.
    #
    # @param api_base_url [String] URL of `api.php` file in your MediaWiki
    #   installation. Typically, its `<domain>/w/api.php`, but can vary
    #   in different wikis.
    # @param user_agent [String] (also aliased as `:ua`) Custom User-Agent header.
    def initialize(api_base_url, ua: nil, user_agent: ua)
      @api_base_url = Addressable::URI.parse(api_base_url)
      @api = MediaWiktory::Wikipedia::Api.new(api_base_url, user_agent: user_agent(user_agent))
      @traits = Traits.get(@api_base_url.host, siteinfo)
    end

    # Receive "raw" data from Wikipedia (without parsing or wrapping in
    # classes).
    #
    # @param titles [Array<String>] List of page titles to get.
    # @param processor [Proc] Optional block to preprocess MediaWiktory query. Refer to
    #   [MediaWiktory::Actions::Query](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query)
    #   for its API. Infoboxer assumes that the block returns new instance of `Query`, so be careful
    #   while using it.
    #
    # @return [Hash{String => Hash}] Hash of `{requested title => raw MediaWiki object}`. Note that
    #   even missing (does not exist in current Wiki) or invalid (impossible title) still be present
    #   in response, just will have `"missing"` or `"invalid"` key, just like MediaWiki returns them.
    def raw(*titles, &processor)
      # could emerge on "automatically" created page lists, should work
      return {} if titles.empty?

      titles.each_slice(50).map do |part|
        request = prepare_request(@api.query.titles(*part), &processor)
        response = request.response

        # If additional props are required, there may be additional pages, even despite each_slice(50)
        response = response.continue while response.continue?

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
    # @param interwiki [Symbol] Identifier of other wiki, related to current, to fetch pages from.
    # @param processor [Proc] Optional block to preprocess MediaWiktory query. Refer to
    #   [MediaWiktory::Actions::Query](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query)
    #   for its API. Infoboxer assumes that the block returns new instance of `Query`, so be careful
    #   while using it.
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
    def get(*titles, interwiki: nil, &processor)
      return interwikis(interwiki).get(*titles, &processor) if interwiki

      pages = get_h(*titles, &processor).values.compact
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
    # @param processor [Proc] Optional block to preprocess MediaWiktory query. Refer to
    #   [MediaWiktory::Actions::Query](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query)
    #   for its API. Infoboxer assumes that the block returns new instance of `Query`, so be careful
    #   while using it.
    #
    # @return [Hash<String, Page>]
    #
    def get_h(*titles, &processor)
      raw_pages = raw(*titles, &processor)
                  .tap { |ps| ps.detect { |_, p| p['invalid'] }.tap { |_, i| i && fail(i['invalidreason']) } }
                  .reject { |_, p| p.key?('missing') }
      titles.map { |title| [title, make_page(raw_pages, title)] }.to_h
    end

    # Receive list of parsed MediaWiki pages from specified category.
    #
    # @param title [String] Category title. You can use namespaceless title (like
    #     `"Countries in South America"`), title with namespace (like
    #     `"Category:Countries in South America"`) or title with local
    #     namespace (like `"Catégorie:Argentine"` for French Wikipedia)
    # @param limit [Integer, "max"]
    # @param processor [Proc] Optional block to preprocess MediaWiktory query. Refer to
    #   [MediaWiktory::Actions::Query](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query)
    #   for its API. Infoboxer assumes that the block returns new instance of `Query`, so be careful
    #   while using it.
    #
    # @return [Tree::Nodes<Page>] array of parsed pages.
    #
    def category(title, limit: 'max', &processor)
      title = normalize_category_title(title)

      list(@api.query.generator(:categorymembers).title(title), limit, &processor)
    end

    # Receive list of parsed MediaWiki pages for provided search query.
    # See [MediaWiki API docs](https://www.mediawiki.org/w/api.php?action=help&modules=query%2Bsearch)
    # for details.
    #
    # @param query [String] Search query. For old installations, look at
    #     https://www.mediawiki.org/wiki/Help:Searching
    #     for search syntax. For new ones (including Wikipedia), see at
    #     https://www.mediawiki.org/wiki/Help:CirrusSearch.
    # @param limit [Integer, "max"]
    # @param processor [Proc] Optional block to preprocess MediaWiktory query. Refer to
    #   [MediaWiktory::Actions::Query](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query)
    #   for its API. Infoboxer assumes that the block returns new instance of `Query`, so be careful
    #   while using it.
    #
    # @return [Tree::Nodes<Page>] array of parsed pages.
    #
    def search(query, limit: 'max', &processor)
      list(@api.query.generator(:search).search(query), limit, &processor)
    end

    # Receive list of parsed MediaWiki pages with titles startin from prefix.
    # See [MediaWiki API docs](https://www.mediawiki.org/w/api.php?action=help&modules=query%2Bprefixsearch)
    # for details.
    #
    # @param prefix [String] Page title prefix.
    # @param limit [Integer, "max"]
    # @param processor [Proc] Optional block to preprocess MediaWiktory query. Refer to
    #   [MediaWiktory::Actions::Query](http://www.rubydoc.info/gems/mediawiktory/MediaWiktory/Wikipedia/Actions/Query)
    #   for its API. Infoboxer assumes that the block returns new instance of `Query`, so be careful
    #   while using it.
    #
    # @return [Tree::Nodes<Page>] array of parsed pages.
    #
    def prefixsearch(prefix, limit: 'max', &processor)
      list(@api.query.generator(:prefixsearch).search(prefix), limit, &processor)
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

    def list(query, limit, &processor)
      request = prepare_request(query.limit(limit), &processor)
      response = request.response

      response = response.continue while response.continue? && (limit == 'max' || response['pages'].count < limit)

      return Tree::Nodes[] if response['pages'].nil?

      pages = response['pages']
              .values.select { |p| p['missing'].nil? }
              .map { |raw| Page.new(self, Parser.paragraphs(raw['revisions'].first['*'], traits), raw) }

      Tree::Nodes[*pages]
    end

    def prepare_request(request)
      request = request.prop(:revisions, :info).prop(:content, :timestamp, :url).redirects
      block_given? ? yield(request) : request
    end

    def normalize_category_title(title)
      # FIXME: shouldn't it go to MediaWiktory?..
      namespace, titl = title.include?(':') ? title.split(':', 2) : [nil, title]
      namespace, titl = nil, title unless traits.category_namespace.include?(namespace)

      namespace ||= traits.category_namespace.first
      [namespace, titl].join(':')
    end

    def user_agent(custom)
      custom || self.class.user_agent || UA
    end

    def siteinfo
      @siteinfo ||= @api.query.meta(:siteinfo).prop(:namespaces, :namespacealiases, :interwikimap).response.to_h
    end

    def interwikis(prefix)
      @interwikis ||= Hash.new { |h, pre|
        interwiki = siteinfo['interwikimap'].detect { |iw| iw['prefix'] == prefix } or
          fail ArgumentError, "Undefined interwiki: #{prefix}"

        # FIXME: fragile, but what can we do?..
        m = interwiki['url'].match(%r{^(.+)/wiki/\$1$}) or
          fail ArgumentError, "Interwiki #{interwiki} seems not to be a MediaWiki instance"
        h[pre] = self.class.new("#{m[1]}/w/api.php") # TODO: copy useragent
      }

      @interwikis[prefix]
    end
  end
end
