# encoding: utf-8
module Infoboxer
  class Page < Document
    def initialize(client, children, raw)
      @client = client
      super(children, raw)
    end

    def_readers :title, :url
  end
end
