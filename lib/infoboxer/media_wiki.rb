# encoding: utf-8
require 'rest-client'
require 'json'
require 'addressable/uri'

require_relative 'media_wiki/traits'

module Infoboxer
  class MediaWiki
    PageNotFound = Class.new(RuntimeError)

    UA = "Infoboxer/#{Infoboxer::VERSION} (https://github.com/molybdenum99/infoboxer; zverok.offline@gmail.com)"

    class << self
      attr_accessor :user_agent
    end
    
    def initialize(api_base_url, options = {})
      @api_base_url = Addressable::URI.parse(api_base_url)
      @resource = RestClient::Resource.new(api_base_url, headers: headers(options))
    end

    attr_reader :api_base_url

    PROP = [
      'revisions',    # to extract content of the page
      'info',         # to extract page canonical url
      'categories',   # to extract default category prefix
      'images'        # to extract default media prefix
    ].join('|')

    def raw(*titles)
      postprocess(@resource.get(
        params: {
          titles:    titles.join('|'),
          
          action:    :query,
          format:    :json,
          redirects: true,

          prop:      PROP,
          rvprop:    :content,
          inprop:    :url,
        }
      ))
    end

    def get(*titles)
      pages = raw(*titles).map{|raw|
        traits = Traits.get(@api_base_url.host, extract_traits(raw))
        
        Page.new(self,
          Parser.paragraphs(raw[:content], traits),
          raw.merge(traits: traits))
      }
      pages.count == 1 ? pages.first : Nodes[*pages]
    end

    private

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
        id == '-1' and
          fail(PageNotFound, "Page with title #{data['title']} not found")
        
        {
          title: data['title'],
          content: data['revisions'].first['*'],
          url: data['fullurl'],
        }.merge(traits)
      }
    rescue JSON::ParserError
      fail RuntimeError, "Not a JSON response, seems there's not a MediaWiki API: #{@api_base_url}"
    end
  end
end
