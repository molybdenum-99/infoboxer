# encoding: utf-8
module Infoboxer
  class MediaWiki
    # A descendant of {Tree::Document Document}, representing page,
    # received from {MediaWiki} client.
    #
    # Alongside with document tree structure, knows document's title as
    # represented by MediaWiki and human (non-API) URL.
    class Page < Tree::Document
      def initialize(client, children, raw)
        @client = client
        super(children, raw)
      end

      # Instance of {MediaWiki} which this page was received from
      # @return {MediaWiki}
      attr_reader :client

      # @!attribute [r] title
      #   Page title.
      #   @return [String]

      # @!attribute [r] url
      #   Page friendly URL.
      #   @return [String]

      def_readers :title, :url, :traits

      private

      PARAMS_TO_INSPECT = [:url, :title, :domain]

      def show_params
        super(params.select{|k, v| PARAMS_TO_INSPECT.include?(k)})
      end
    end
  end
end
