# encoding: utf-8
require 'procme'

module Infoboxer
  WIKIPEDIA_API_URL = 'http://%s.wikipedia.org/w/api.php'
  WIKIA_API_URL = 'http://%s.wikia.com/api.php'

  class << self
    def wiki(api_url)
      MediaWiki.new(api_url)
    end
    
    def wikipedia(lang = 'en')
      wiki(WIKIPEDIA_API_URL % lang)
    end

    alias_method :wp, :wikipedia

    def wikia(*domains)
      wiki(WIKIA_API_URL % domains.reverse.join('.'))
    end
  end
end

require_relative 'infoboxer/core_ext'

require_relative 'infoboxer/media_wiki'

require_relative 'infoboxer/node'
require_relative 'infoboxer/nodes'
require_relative 'infoboxer/document'
require_relative 'infoboxer/parser'

require_relative 'infoboxer/page'
