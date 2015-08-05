# encoding: utf-8
module Infoboxer
  # Infoboxer provides you with tree structure of the Wikipedia page,
  # which you can introspect and navigate with ease. This tree structure
  # tries to be simple, close to Wikipedia source and logical.
  #
  # You can always inspect entire page tree yourself:
  #
  # ```ruby
  # page = Infoboxer.wp.get('Argentina')
  # puts page.to_tree
  # ```
  #
  # ## Inspecting and understanding single node
  #
  # Each tree node is descendant of {Tree::Node}, so you should look
  # at this class to understand what you can do.
  #
  # Alongside with basic methods, defined in Node class, some useful
  # utility methods are defined in subclasses.
  #
  # Here's full list of subclasses, representing real nodes, with their
  # respective roles:
  #
  # * inline markup: {Text}, {Bold}, {Italic}, {BoldItalic}, {Wikilink},
  #   {ExternalLink}, {Image};
  # * embedded HTML: {HTMLTag}, {HTMLOpeningTag}, {HTMLClosingTag};
  # * paragraph-level nodes: {Heading}, {Paragraph}, {Pre}, {HR};
  # * lists: {OrderedList}, {UnorderedList}, {DefinitionList}, {ListItem},
  #   {DTerm}, {DDefinition};
  # * tables: {Table}, {TableCaption}, {TableRow}, {TableHeading}, {TableCell};
  # * special elements: {Template}, {Ref}.
  #
  # ## Tree navigation
  #
  # {Tree::Node} class has a standard list of methods for traversing tree
  # upwards, downwards and sideways: `children`, `parent`, `siblings`,
  # `index`. Read through class documentation for their detailed
  # descriptions.
  #
  # {Navigation} module contains more advanced navigational functionality,
  # like XPath-like selectors, friendly shortcuts, breakup of document
  # into logical "sections" and so on.
  #
  # Most of navigational and other Node's methods return {Nodes} type,
  # which is an `Array` descendant with additional functionality.
  # 
  # ## Complex data extraction
  #
  # Most of uniform, machine-extractable data in Wikipedia is stored in
  # templates and tables. There's entire {Templates} module, which is
  # documented explaining what you can do about Wikipedia templates, how
  # to understand them and use information. Also, you can look at {Table}
  # class, which for now is not that powerful, yet allows you to extract
  # some columns and rows.
  #
  # Also, consider that WIKIpedia is maid of WIKIlinks, and {Wikilink#follow}
  # (as well as {Nodes#follow} for multiple links at once) is you good friend.
  #
  module Tree
    require_relative 'tree/node'
    require_relative 'tree/nodes'

    %w[text compound inline
      image html paragraphs list template table ref
      document].each do |type|
      require_relative "tree/#{type}"
    end
  end
end
