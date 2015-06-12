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
        traits = Traits.get(@api_base_url.host, extract_traits(raw))
        
        Page.new(self,
          Parser.paragraphs(raw[:content], traits),
          raw.merge(traits: traits))
      }
      pages.count == 1 ? pages.first : pages
    end

    private

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
    end
  end
end
