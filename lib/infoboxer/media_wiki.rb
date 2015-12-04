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

    attr_reader :api_base_url

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
      #@resource = RestClient::Resource.new(api_base_url, headers: headers(options))
      @client = MediaWiktory::Client.new(api_base_url) # TODO: user agen header
    end

    # Receive "raw" data from Wikipedia (without parsing or wrapping in
    # classes).
    #
    # @return [Array<Hash>]
    def raw(*titles)
      #postprocess @resource.get(
        #params: DEFAULT_PARAMS.merge(titles: titles.join('|'))
      #)
      @client.query.
        titles(*titles).
        prop(revisions: {prop: ['content']}, info: {prop: ['url']}).
        perform.pages
    end

    # Receive list of parsed wikipedia pages for list of titles provided.
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
      pages = raw(*titles).reject{|raw| raw[:content].nil?}.
        map{|raw|
          traits = Traits.get(@api_base_url.host, extract_traits(raw))
          
          Page.new(self,
            Parser.paragraphs(raw[:content], traits),
            raw.merge(traits: traits))
        }
      titles.count == 1 ? pages.first : Tree::Nodes[*pages]
    end

    private

    # @private
    PROP = [
      'revisions',    # to extract content of the page
      'info',         # to extract page canonical url
      'categories',   # to extract default category prefix
      'images'        # to extract default media prefix
    ].join('|')

    # @private
    DEFAULT_PARAMS = {
      action:    :query,
      format:    :json,
      redirects: true,

      prop:      PROP,
      rvprop:    :content,
      inprop:    :url,
    }

    def headers(options)
      {'User-Agent' => options[:user_agent] || options[:ua] || self.class.user_agent || UA}
    end

    def extract_traits(raw)
      raw.select{|k, v| [:file_prefix, :category_prefix].include?(k)}
    end

    def guess_traits(pages)
      categories = pages.map{|p| p['categories']}.compact.flatten
      images = pages.map{|p| p['images']}.compact.flatten
      {
        file_prefix: images.map{|i| i['title'].scan(/^([^:]+):/)}.flatten.uniq,
        category_prefix: categories.map{|i| i['title'].scan(/^([^:]+):/)}.flatten.uniq,
      }
    end

    def postprocess(response)
      pages = JSON.parse(response)['query']['pages']
      traits = guess_traits(pages.values)
      
      pages.map{|id, data|
        if id.to_i < 0
          {
            title: data['title'],
            content: nil,
            not_found: true
          }
        else
          {
            title: data['title'],
            content: data['revisions'].first['*'],
            url: data['fullurl'],
          }.merge(traits)
        end
      }
    rescue JSON::ParserError
      fail RuntimeError, "Not a JSON response, seems there's not a MediaWiki API: #{@api_base_url}"
    end
  end
end
