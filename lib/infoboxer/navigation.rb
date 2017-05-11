# encoding: utf-8

module Infoboxer
  # Navigation is one of the things Infoboxer is proud about. It tries
  # to be logical, unobtrusive and compact.
  #
  # There's several levels of navigation:
  # * simple tree navigation;
  # * navigational shortcuts;
  # * logical structure navigation (sections).
  #
  # ## Simple tree navigation
  #
  # It's somewhat similar to XPath/CSS selectors you'll use to navigate
  # through HTML DOM. It is represented (and documented) in {Lookup::Node}
  # module. To show you the taste of it:
  #
  # ```ruby
  # document.
  #  lookup(:Wikilink, text: /Chile/).
  #  lookup_parents(:Table){|t| t.params[:class] == 'wikitable'}.
  #  lookup_children(size: 3)
  # ```
  #
  # ## Navigational shortcuts
  #
  # There is nothing too complicated, just pretty shortcuts over `lookup_*`
  # methods, so, you can write just
  #
  # ```ruby
  # document.paragraphs.last.wikilinks('Category')
  # ```
  # ...instead of
  # ```ruby
  # document.lookup(:Paragraph).last.lookup(:Wikilink, namespace: 'Category')
  # ```
  # ...and so on.
  #
  # Look into {Shortcuts::Node} documentation for list of shortcuts.
  #
  # ## Logical structure navigation
  #
  # MediaWiki page structure is flat, like HTML's (there's just sequence
  # of headings and paragraphs). Though, for most tasks of information
  # extraction it is usefult to think of page as a structure of nested
  # sections. {Sections} module provides such ability. It treats document
  # as an {Sections::Container#intro intro} and set of subsequent
  # {Sections::Section section}s of same level, which, in turn, have inside
  # they own intro and sections. Also, each node has
  # {Sections::Node#in_sections #in_sections} method, returning all sections
  # in which it is nested.
  #
  # The code with sections can feel like this:
  #
  # ```ruby
  # page.sections('Culture' => 'Music').tables
  # # or like this
  # page.wikilinks.select{|link| link.in_sections.first.heading.text.include?('Culture')}
  # ```
  #
  # See {Sections::Container} for downwards section navigation, and
  # {Sections::Node} for upwards.
  #
  module Navigation
    %w[lookup shortcuts sections].each do |nav|
      require_relative "navigation/#{nav}"
    end

    class Tree::Node
      include Navigation::Lookup::Node
      include Navigation::Shortcuts::Node
      include Navigation::Sections::Node
    end

    class Tree::Nodes
      include Navigation::Lookup::Nodes
      include Navigation::Shortcuts::Nodes
      include Navigation::Sections::Nodes
    end

    class Tree::Document
      include Navigation::Sections::Container
    end
  end
end
