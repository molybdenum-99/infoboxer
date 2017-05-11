# Infoboxer's change log

## 0.2.8 (2017-05-11)

* Switch to MediaWiktory 0.1.0 + some subsequent cleanup of internal logic;
* Additional `prop:` param for `MediaWiki#get`, `#get_h`, and `#raw`, allowing to fetch arbitrary
  page properties.

## 0.2.7 (2016-09-18)

* Fix `Math` node rendering to text (#68);
* Fix consequtive apostrophes problem (#69);
* Fix math parsing in templates (#70).

## 0.2.6 (2016-06-27)

_0.2.5 was erroneously released without any changes._

* Fix of `<math>` tags parsing (#66)

## 0.2.4 (2016-04-16)

* `MediaWiki#get_h` works correctly with several synonymous pages now;
* `get` and `get_h` work better when some of required titles are downcase;
* Travis compatibility check restored.

## 0.2.3 (2016-03-02)

New and enchanced features:
* more useful templates (quick-n-dirty sometimes, but prettier output for
  typical cases);
* Caching of wikiobjects, so for several calls to `Infoboxer.wp` it would
  be only one API call for wiki metainformation;
* `MediaWiki#get` now preserves order of pages (page list would be in
  the same order as requested titles);
* `MediaWiki#get_h` to receive hash of `title => page object` (useful
  to know which titles have been no pages for and better control on
  redirects).

Fixes:
* `Image` node equality fixed.

## 0.2.2 (2016-01-03)

Fixes:
* more sophisticated table parsing;
* empty `<nowiki/>` is parsed properly;
* inline unclosed markup inside wikilinks works;
* `MediaWiki::Traits` can now be continued in several places.

## 0.2.1 (2015-12-21)

* `infoboxer` binary properly registered.

## 0.2.0 (2015-12-21)

* MediaWiki backend changed to (our own handcrafted)
  [mediawiktory](https://github.com/molybdenum-99/mediawiktory);
* Added page lists fetching like `MediaWiki#category(categoryname)`,
  `MediaWiki#search(search_phrase)`;
* `MediaWiki#get` now can fetch any number of pages at once (it was only
  50 in previous versions);
* `bin/infoboxer` console added for quick experimenting;
* `Template#to_h` added for quick information extraction;
* many small bugfixes and enchancements.

## 0.1.2.1 (2015-12-04)

* Small bug with newlines in templates fixed.

## 0.1.2 (2015-08-18)

Aaaaand, rrrrrelease it into the wilde!

* `ImageCaption` class added;
* Smallest refactorings;
* More documentation fixes.


## 0.1.1 (2015-08-11)

Basically, preparing for wider release!

* Small refactorings;
* Documentation fixes.

## 0.1.0 (2015-08-07)

Initial (ok, I know it's typically called 0.0.1, but here's work of
three monthes, numerous documentations and examples and so on... so, let
it be 0.1.0).
