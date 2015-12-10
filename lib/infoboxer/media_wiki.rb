# encoding: utf-8
#require 'rest-client'
#require 'json'
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
  # client = Infoboxer::MediaWiki.new('http://en.wikipedia.org/w/api.php', user_agent: 'My Own Project')
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
    UA = "Infoboxer/#{Infoboxer::VERSION} (https://github.com/molybdenum-99/infoboxer; zverok.offline@gmail.com)"

    class << self
      # User agent getter/setter.
      #
      # Default value is {UA}.
      #
      # You can also use per-instance option, see {#initialize}
      attr_accessor :user_agent
    end

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
      @client = MediaWiktory::Client.new(api_base_url, user_agent: user_agent(options))
      @traits = Traits.get(@api_base_url.host, namespaces: extract_namespaces)
    end

    # Receive "raw" data from Wikipedia (without parsing or wrapping in
    # classes).
    #
    # @return [Array<Hash>]
    def raw(*titles)
      @client.query.
        titles(*titles).
        prop(revisions: {prop: :content}, info: {prop: :url}).
        redirects(true). # FIXME: should be done transparently by MediaWiktory?
        perform.pages
    end

    # Receive list of parsed MediaWiki pages for list of titles provided.
    # All pages are received with single query to MediaWiki API.
    #
    # **NB**: currently, if you are requesting more than 50 titles at
    # once (MediaWiki limitation for single request), Infoboxer will
    # **not** try to get other pages with subsequent queries. This will
    # be fixed in future.
    #
    # @return [Tree::Nodes<Page>] array of parsed pages. Notes:
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
    #     and obtain meaningful results instead of NoMethodError or some
    #     NotFound.
    #
    def get(*titles)
      pages = raw(*titles).select(&:exists?).
        map{|raw|
          Page.new(self,
            Parser.paragraphs(raw.content, traits),
            raw)
        }
      titles.count == 1 ? pages.first : Tree::Nodes[*pages]
    end

    # Receive list of parsed MediaWiki pages from specified category.
    #
    # **NB**: currently, this API **always** fetches all pages from
    # category, there is no option to "take first 20 pages". Pages are
    # fetched in 50-page batches, then parsed. So, for large category
    # it can really take a while to fetch all pages.
    #
    # @param title Category title. You can use namespaceless title (like
    #     `"Countries in South America"`), title with namespace (like 
    #     `"Category:Countries in South America"`) or title with local
    #     namespace (like `"Catégorie:Argentine"` for French Wikipedia)
    #
    # @return [Tree::Nodes<Page>] array of parsed pages.
    #
    def category(title)
      title = normalize_category_title(title)
      
      response = @client.query.
        generator(categorymembers: {title: title, limit: 50}).
        prop(revisions: {prop: :content}, info: {prop: :url}).
        redirects(true). # FIXME: should be done transparently by MediaWiktory?
        perform

      response.continue! while response.continue?

      pages = response.pages.select(&:exists?).
        map{|raw|
          Page.new(self,
            Parser.paragraphs(raw.content, traits),
            raw)
        }

      Tree::Nodes[*pages]
    end

    private

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
      siteinfo = @client.query.meta(siteinfo: {prop: [:namespaces, :namespacealiases]}).perform
      siteinfo.raw.query.namespaces.map{|_, namespace|
        aliases = siteinfo.raw.query.namespacealiases.select{|a| a.id == namespace.id}.map{|a| a['*']}
        namespace.merge(aliases: aliases)
      }
    end
  end
end
