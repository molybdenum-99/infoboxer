# encoding: utf-8

require_relative '../wiki_path'

module Infoboxer
  module Navigation
    module Wikipath
      def wikipath(string)
        Infoboxer::WikiPath.parse(string).call(self)
      end
    end
  end
end
