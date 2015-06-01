# encoding: utf-8
require 'rest-client'
require 'json'
require 'addressable/uri'

module Infoboxer
  class MediaWiki
    PageNotFound = Class.new(RuntimeError)
    
    def initialize(api_base_url)
      @api_base_url = Addressable::URI.parse(api_base_url)
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

    def get(*titles)
      pages = raw(*titles).map{|raw|
        Page.new(self, Parser.parse(raw[:content]), raw)
      }
      pages.count == 1 ? pages.first : pages
    end

    # FIXME:
    # * different pathes for different installs, some wikis
    #   have no /wiki/ part in URL
    # * is gsub(' ', '_') enough? :)
    def url_for(title)
      @api_base_url.dup.tap{|d|
        d.path = "/wiki/#{title.gsub(' ', '_')}"
      }.to_s
    end

    private

    def postprocess(response)
      JSON.parse(response)['query']['pages'].map{|id, data|
        id == '-1' and
          fail(PageNotFound, "Page with title #{data['title']} not found")
        
        {
          title: data['title'],
          content: data['revisions'].first['*']
        }
      }
    end
  end
end
