module Infoboxer
  class Configuration
    DEFAULTS = {
      user_agent: MediaWiki::UA
    }

    def initialize(**options)
      parse_options(options)
    end

    def add_option(key, val)
      singleton_class.class_eval { attr_accessor key }
      instance_variable_set("@#{key}", val)
    end

    private

    def parse_options(hash)
      hash = DEFAULTS.merge(hash)
      hash.each_pair { |k, v| add_option(k, v) }
    end
  end
end
