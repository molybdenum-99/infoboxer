# encoding: utf-8
require 'procme'

module Infoboxer
  WIKIPEDIA_API_URL = 'http://%s.wikipedia.org/w/api.php'
  WIKIA_API_URL = 'http://%s.wikia.com/api.php'

  class << self
    def wiki(api_url, options = {})
      MediaWiki.new(api_url, options = {})
    end
    
    def wikipedia(lang = 'en', options = {})
      wiki(WIKIPEDIA_API_URL % lang, options)
    end

    alias_method :wp, :wikipedia

    def wikia(*domains)
      options = domains.last.is_a?(Hash) ? domains.pop : {}
      wiki(WIKIA_API_URL % domains.reverse.join('.'), options)
    end

    def user_agent=(ua)
      MediaWiki.user_agent = ua
    end
  end
end

require_relative 'infoboxer/version'

require_relative 'infoboxer/core_ext'

require_relative 'infoboxer/media_wiki'

require_relative 'infoboxer/node'
require_relative 'infoboxer/nodes'
require_relative 'infoboxer/document'
require_relative 'infoboxer/parser'

require_relative 'infoboxer/page'
