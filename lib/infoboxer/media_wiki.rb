# encoding: utf-8
require 'rest-client'
require 'json'
require 'addressable/uri'

require_relative 'media_wiki/traits'

module Infoboxer
  class MediaWiki
    PageNotFound = Class.new(RuntimeError)
    
    def initialize(api_base_url)
      @api_base_url = Addressable::URI.parse(api_base_url)
      @resource = RestClient::Resource.new(api_base_url)
    end

    attr_reader :api_base_url

    def raw(*titles)
      postprocess(@resource.get(
        params: {
          action: :query,
          
          # revisions for content
          # info for url
          # categories and images to know their prefixes in this wiki
          prop: 'revisions|info|categories|images',
          rvprop: :content,
          inprop: :url,
          format: :json,
          redirects: true,
          titles: titles.join('|')
        }
      ))
    end

    def get(*titles)
      pages = raw(*titles).map{|raw|
        traits = Traits.get(@api_base_url.host, guess_traits(raw))
        
        Page.new(self,
          Parser.paragraphs(raw[:content], traits),
          raw.merge(traits: traits))
      }
      pages.count == 1 ? pages.first : pages
    end

    private

    def guess_traits(raw)
      {
        file_prefix: raw[:images].map{|i| i['title'].scan(/^([^:]+):/)}.flatten.uniq,
        category_prefix: raw[:categories].map{|i| i['title'].scan(/^([^:]+):/)}.flatten.uniq,
      }
    end

    def postprocess(response)
      JSON.parse(response)['query']['pages'].map{|id, data|
        id == '-1' and
          fail(PageNotFound, "Page with title #{data['title']} not found")
        
        {
          title: data['title'],
          content: data['revisions'].first['*'],
          url: data['fullurl'],
          categories: data['categories'],
          images: data['images']
        }
      }
    end
  end
end
