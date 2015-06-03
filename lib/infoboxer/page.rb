# encoding: utf-8
module Infoboxer
  class Page < Document
    def initialize(client, children, raw)
      @client = client
      super(children, raw)
    end

    attr_reader :client

    def_readers :title, :url
  end
end
