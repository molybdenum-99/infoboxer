# encoding: utf-8
require 'rest-client'
require 'json'

module Infoboxer
  class MediaWiki
    PageNotFound = Class.new(RuntimeError)
    
    def initialize(api_base_url)
      @api_base_url = api_base_url
      @resource = RestClient::Resource.new(api_base_url)
    end

    def raw(*titles)
      postprocess(@resource.get(
        params: {
          action: :query,
          prop: :revisions,
          rvprop: :content,
          format: :json,
          redirects: true,
          titles: titles.join('|')
        }
      ))
    end

    private

    def postprocess(response)
      pages = JSON.parse(response)['query']['pages'].map{|id, data|
        id == '-1' and
          fail(PageNotFound, "Page with title #{data['title']} not found")
        
        {
          title: data['title'],
          content: data['revisions'].first['*']
        }
      }
      pages.count == 1 ? pages.first : pages
    end
  end
end
