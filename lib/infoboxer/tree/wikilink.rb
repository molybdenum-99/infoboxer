# encoding: utf-8

require_relative 'linkable'

module Infoboxer
  module Tree
    # Internal MediaWiki link class.
    #
    # See [Wikipedia docs](https://en.wikipedia.org/wiki/Help:Link#Wikilinks)
    # for extensive explanation of Wikilink concept.
    #
    # Note, that Wikilink is {Linkable}, so you can {Linkable#follow #follow}
    # it to obtain linked pages.
    class Wikilink < Link
      def initialize(link, label = nil, namespace: nil, interwiki: nil)
        super(link, label, namespace: namespace, interwiki: interwiki)
        @namespace = namespace || ''
        @interwiki = interwiki
        parse_name!
      end

      # "Clean" wikilink name, for ex., `Cities` for `[Category:Cities]`
      attr_reader :name

      # Interwiki identifier. For example, `[[wikt:Argentina]]`
      # will have `"Argentina"` as its {#name} and `"wikt"` (wiktionary) as an
      # interwiki. TODO: how to use it.
      #
      # See [Wikipedia docs](https://en.wikipedia.org/wiki/Help:Interwiki_linking) for details.
      attr_reader :interwiki

      # Wikilink namespace, `Category` for `[Category:Cities]`, empty
      # string (not `nil`!) for just `[Cities]`
      attr_reader :namespace

      # Anchor part of hyperlink, like `History` for `[Argentina#History]`
      attr_reader :anchor

      # Topic part of link name.
      #
      # There's so-called ["Pipe trick"](https://en.wikipedia.org/wiki/Help:Pipe_trick)
      # in wikilink markup, which defines that `[Phoenix, Arizona]` link
      # has main part ("Phoenix") and refinement part ("Arizona"). So,
      # we are splitting it here in `topic` and {#refinement}.
      # The same way, `[Pipe (programming)]` has `topic == 'Pipe'` and
      # `refinement == 'programming'`
      attr_reader :topic

      # Refinement part of link name.
      #
      # See {#topic} for explanation.
      attr_reader :refinement

      include Linkable

      private

      def parse_name!
        @name = namespace.empty? ? link : link.sub(/^#{namespace}:/, '')
        @name, @anchor = @name.split('#', 2)
        @anchor ||= ''

        parse_topic!
      end

      # @see http://en.wikipedia.org/wiki/Help:Pipe_trick
      def parse_topic!
        @topic, @refinement =
          case @name
          when /^(.+\S)\s*\((.+)\)$/, /^(.+?),\s*(.+)$/
            [Regexp.last_match(1), Regexp.last_match(2)]
          else
            [@name, '']
          end

        return unless children.count == 1 &&
                      children.first.is_a?(Text) && children.first.raw_text.empty?
        children.first.raw_text = @topic
      end
    end
  end
end
