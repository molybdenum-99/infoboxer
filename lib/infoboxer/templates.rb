module Infoboxer
  # This module covers advanced MediaWiki templates usage.
  #
  # It is seriously adviced to read [Wikipedia docs](https://en.wikipedia.org/wiki/Help:Template)
  # or at least look through it (and have it opened while reading further).
  #
  # If you just have a page with templates and want some variable value
  # (like "page about country - infobox - total population"), you should
  # be totally happy with {Tree::Template} and its features.
  #
  # What this module does is, basically, two things:
  # * allow you to define for arbitrary templates how they are converted
  #   to text; by default, templates are totally excluded from text, which
  #   is not most reasonable behavior for many formatting templates;
  # * allow you to define additional functionality for arbitrary templates;
  #   many of them containing pretty complicated logic (see, for ex.,
  #   [Template:Convert](https://en.wikipedia.org/wiki/Template:Convert)),
  #   and it seems reasonable to extend instances of such a template.
  #
  # Infoboxer allows you to define {Templates::Set} of template-specific
  # classes for some site/domain.
  # There is already defined set of most commonly used templates at
  # en.wikipedia.org (so, most of English Wikipedia texts will be rendered
  # correctly, and also some advanced functionality is provided).
  # You can take a look at
  # [lib/infoboxer/definitions/en.wikipedia.org.rb](https://github.com/molybdenum-99/infoboxer/blob/master/lib/infoboxer/definitions/en.wikipedia.org.rb)
  # to feel it (and also see a couple of TODOs and FIXMEs and other
  # considerations).
  #
  # From Infoboxer's point-of-view, templates are the most complex part
  # of Wikipedia, and we are currently trying hard to do the most reasonable
  # things about them.
  #
  # Future versions also should:
  # * define more of common English Wikipedia templates;
  # * define templates for other popular wikis;
  # * allow to add template definitions on-the-fly, while loading some
  #   page.
  #
  module Templates
    %w[base set].each do |tmpl|
      require_relative "templates/#{tmpl}"
    end
  end
end
