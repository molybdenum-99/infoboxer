module Infoboxer
  class Configuration
    DEFAULTS = {
      user_agent: MediaWiki::UA
    }

    # @!method initialize(options = {})
    # @param options Hash of options to set.
    def initialize(**options)
      parse_options(options)
    end

    # @!method add_option(key, val)
    # Creates an accessor for the key, and sets the value.
    # @param key Name of option.
    # @param val Value of option.
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
