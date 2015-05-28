# encoding: utf-8
module Infoboxer
  class Page < Document
    def initialize(client, children, raw)
      @client = client
      super(children, raw)
    end

    def_readers :title

    def url
      @client.url_for(title)
    end
  end
end
