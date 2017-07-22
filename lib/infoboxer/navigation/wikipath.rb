# encoding: utf-8

require_relative '../wiki_path'

module Infoboxer
  module Navigation
    module Wikipath
      # Search nodes inside current by XPath alike query language.
      #
      # This feature is experimental, but should work for most of the useful cases.
      #
      # Examples of WikiPath:
      #
      # ```
      # /paragraph # direct child of current node, being paragraph
      # //paragraph # any node in current node's subtree, being paragraph
      # //template[name=Infobox] # template node in subtree, with name attribute equal to Infobox
      # //template[name="Infobox country"] # optional quotes are allowed
      # //template[name=/^Infobox/] # regexes are supported
      # //wikilink[italic] # node predicates are supported (the same as `lookup(:Wikilink, :italic?)`
      # //*[italic] # type wildcards are supported
      # //template[name=/^Infobox/]/var[name=birthday] # series of lookups work
      # ```
      #
      # @param string [String] WikiPath to lookup
      # @return [Nodes]
      def wikipath(string)
        Infoboxer::WikiPath.parse(string).call(self)
      end
    end
  end
end
