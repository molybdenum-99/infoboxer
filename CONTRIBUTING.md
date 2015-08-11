# Contributing to Infoboxer

_(Also duplicated in [wiki](https://github.com/molybdenum-99/infoboxer/wiki/Contributing).)_

## Contributing via test cases

If you are assured that Infoboxer takes some page wrong, please create an
[issue](https://github.com/molybdenum-99/infoboxer/issues) with link
to page (or raw wikitext) and description of a problem.

## Contributing via localizations and templates describing

Look at [en.wikipedia.org](https://github.com/molybdenum-99/infoboxer/blob/master/lib/infoboxer/definitions/en.wikipedia.org.rb)
template definitions. It can be extended. Also, similar definitions
can/should be created for other language wikipedias and other popular
wikis.

You can do pull requests with your own definitions, or create an
[issue](https://github.com/molybdenum-99/infoboxer/issues) describing
which template definitions should be added to Infoboxer.

## Contributing via code

If you want to fix some bug or implement some feature, please just
follow the standard process for github opensource: fork, fix, push,
make pull request.

Some (scanty) information below.

### Understanding the code

* Infoboxer is splitted in several modules (which are clearly visible in
  API docs and folders structure).
* Most of "easy features"
  can be added to [Navigation](http://www.rubydoc.info/gems/infoboxer/Infoboxer/Navigation)
  module and its submodules: enchancing of navigational experience and
  implement clever shortcuts (like "converting table to dataframe/list of
  hashes", for ex.).
* Most of potential bugs can seat in
  [Parser](http://www.rubydoc.info/gems/infoboxer/Infoboxer/Parser) class
  and its modules; MediaWiki markup IS tricky and tightly coupled and
  ambigous; there's also some non-implemented features, like `<source>`
  tag parsing and template definition pages (which, possibly, is not
  target of Infoboxer anyways).
* Most of underfeatured area is in
  [MediaWiki](http://www.rubydoc.info/gems/infoboxer/Infoboxer/MediaWiki)
  -- seems reasonable for information extraction purposes to have more
  features from MediaWiki API, like "page list generators", search,
  "what links here" and similar functionality.
* Most of clarification and documentation is required for 
  [Templates](http://www.rubydoc.info/gems/infoboxer/Infoboxer/Templates)
  module, which is still underloved heart of Infoboxer.

### Parser: quick, not clever

Whether you'd want to put your hands on Parser: please remember, that
it's hand-crafted and thoroughly optimized. The first thought you may
have that it needs more OO decompozition, a class for each case; or more
ideomatic Ruby, or ... Trust me, I've tried it all. But when you are
dealing with hundreds of thousands of parsing operations and tens of
thousands of resulting nodes, it turns out even simplest things like
`Object#tap` have performance penalty on large number of calls.
