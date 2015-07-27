# encoding: utf-8
require 'procme'
require 'backports/2.1.0/array/to_h'
#require 'backports/2.2.0/object/itself' Y U NO???

# Main client module for entire infoboxer functionality. If you're lucky,
# there's no other classes/modules you need to instantiate or call
# directly. You just do:
#
# ```ruby
# Infoboxer.wp.get('List of radio telescopes')
# # or 
# Infoboxer.wikiquote.get('Vonnegut')
# ```
# ...and have fully navigable Wiki information.
#
# Please read [wiki](http://github.com/molybdenum-99/infoboxer/wiki)
# for extensive showcases and usage examples
#
module Infoboxer
  WIKIA_API_URL = 'http://%s.wikia.com/api.php'

  class << self

    # Default method for call any Wiki API
    #
    # @param api_url should be URL of api.php for your MediaWiki
    # @param options list of options.
    #   The only recognized option for now, though, is
    #   * `:user_agent` (also aliased as `:ua`) -- custom User-Agent header.
    #
    def wiki(api_url, options = {})
      MediaWiki.new(api_url, options || {})
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

    # @!method wikipedia(lang = 'en', options = {})
    # Performs request to Wikipedia.
    #
    # @param lang two-character code for language version
    # @param options (see #wiki for list of options)
    
    # @!method wikivoyage(lang = 'en', options = {})
    # Performs request to Wikivoyage. See {wikipedia} for params explanation.

    # @!method wikiquote(lang = 'en', options = {})
    # Performs request to Wikiquote. See {wikipedia} for params explanation.

    # @!method wiktionary(lang = 'en', options = {})
    # Performs request to Wiktionary. See {wikipedia} for params explanation.

    # @!method wikibooks(lang = 'en', options = {})
    # Performs request to Wikibooks. See {wikipedia} for params explanation.

    # @!method wikinews(lang = 'en', options = {})
    # Performs request to Wikinews. See {wikipedia} for params explanation.

    # @!method wikiversity(lang = 'en', options = {})
    # Performs request to Wikiversity. See {wikipedia} for params explanation.

    # @!method commons(options = {})
    # Performs request to WikiMedia Commons.
    #
    # @param options (see #wiki for list of options)
    
    # @!method species(options = {})
    # Performs request to WikiMedia Species.
    #
    # @param options (see #wiki for list of options)
    
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

    # Performs request to wikia.com wikis.
    # @param *domains list of domains to merge, like this:
    #
    #   ```ruby
    #   Infoboxer.wikia('tardis') # looks at tardis.wikia.com
    #   Infoboxer.wikia('tardis', 'ru') # looks in Russian version, ru.tardis.wikia.com
    #   ```
    #   If you are surprised by "reversing" list of subdomains, think of
    #   it as of chain of refinements (looking in "tardis" wiki, its "ru" 
    #   version, specifically).
    #
    # @param options just last of params, if it is hash
    #   (see {wiki} for list of options)
    #
    def wikia(*domains)
      options = domains.last.is_a?(Hash) ? domains.pop : {}
      wiki(WIKIA_API_URL % domains.reverse.join('.'), options)
    end

    # Sets user agent string globally. Default user agent is 
    # {MediaWiki::UA}.
    #
    # User agent can also be rewriten as an option to {wiki} method (and
    # its shortcuts like {wikipedia}), or by using {MediaWiki#initialize}
    # explicitly.
    #
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

require_relative 'infoboxer/navigation'

require_relative 'infoboxer/template_set'

require_relative 'infoboxer/page'

require_relative 'infoboxer/media_wiki/traits/en.wikipedia.org'
