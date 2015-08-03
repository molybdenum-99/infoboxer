# encoding: utf-8
module Infoboxer
  class MediaWiki
    class Page < Tree::Document
      def initialize(client, children, raw)
        @client = client
        super(children, raw)
      end

      attr_reader :client

      def_readers :title, :url, :traits

      private

      PARAMS_TO_INSPECT = [:url, :title, :domain]

      def show_params
        super(params.select{|k, v| PARAMS_TO_INSPECT.include?(k)})
      end
    end
  end
end
