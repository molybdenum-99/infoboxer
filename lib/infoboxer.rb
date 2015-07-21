# encoding: utf-8
require 'procme'
require 'backports/2.1.0/array/to_h'
#require 'backports/2.2.0/object/itself' Y U NO???

module Infoboxer
  WIKIA_API_URL = 'http://%s.wikia.com/api.php'

  class << self
    def wiki(api_url, options = {})
      MediaWiki.new(api_url, options = {})
    end

    WIKIMEDIA_PROJECTS = {
      wikipedia: 'wikipedia.org',
      wikivoyage: 'wikivoyage.org',
      wikiquote: 'wikiquote.org',
      wiktionary: 'wiktionary.org',
      wikibooks: 'wikibooks.org',
      wikinews: 'wikinews.org',
      wikiversity: 'wikiversity.org',
    }

    WIKIMEDIA_COMMONS = {
      commons: 'commons.wikimedia.org',
      species: 'species.wikimedia.org'
    }

    WIKIMEDIA_PROJECTS.each do |name, domain|
      define_method name do |lang = 'en', options = {}|
        if lang.is_a?(Hash)
          lang, options = 'en', lang
        end

        wiki("http://#{lang}.#{domain}/w/api.php", options)
      end
    end

    alias_method :wp, :wikipedia

    WIKIMEDIA_COMMONS.each do |name, domain|
      define_method name do |options = {}|
        wiki("http://#{domain}/w/api.php", options)
      end
    end


    def wikia(*domains)
      options = domains.last.is_a?(Hash) ? domains.pop : {}
      wiki(WIKIA_API_URL % domains.reverse.join('.'), options)
    end

    def user_agent=(ua)
      MediaWiki.user_agent = ua
    end

    private
  end
end

require_relative 'infoboxer/version'

require_relative 'infoboxer/core_ext'

require_relative 'infoboxer/media_wiki'

require_relative 'infoboxer/node'
require_relative 'infoboxer/nodes'
require_relative 'infoboxer/document'
require_relative 'infoboxer/parser'

require_relative 'infoboxer/navigation/lookup'

require_relative 'infoboxer/template_set'

require_relative 'infoboxer/page'

require_relative 'infoboxer/media_wiki/traits/en.wikipedia.org'
