module Infoboxer
  class MediaWiki
    # A descendant of {Tree::Document Document}, representing page,
    # received from {MediaWiki} client.
    #
    # Alongside with document tree structure, knows document's title as
    # represented by MediaWiki and human (non-API) URL.
    class Page < Tree::Document
      def initialize(client, children, source)
        @client, @source = client, source
        super(children, title: source['title'], url: source['fullurl'])
      end

      # Instance of {MediaWiki} which this page was received from
      # @return {MediaWiki}
      attr_reader :client

      # Instance of MediaWiktory::Page class with source data
      # @return {MediaWiktory::Page}
      attr_reader :source

      # @!attribute [r] title
      #   Page title.
      #   @return [String]

      # @!attribute [r] url
      #   Page friendly URL.
      #   @return [String]

      def_readers :title, :url

      def traits
        client.traits
      end

      private

      PARAMS_TO_INSPECT = %i[url title].freeze

      def show_params
        super(params.select { |k, _v| PARAMS_TO_INSPECT.include?(k) })
      end
    end
  end
end
