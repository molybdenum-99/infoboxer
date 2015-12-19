# Infoboxer

[![Gem Version](https://badge.fury.io/rb/infoboxer.svg)](http://badge.fury.io/rb/infoboxer)
[![Build Status](https://travis-ci.org/molybdenum-99/infoboxer.svg?branch=master)](https://travis-ci.org/molybdenum-99/infoboxer)
[![Coverage Status](https://coveralls.io/repos/molybdenum-99/infoboxer/badge.svg?branch=master&service=github)](https://coveralls.io/github/molybdenum-99/infoboxer?branch=master)
[![Code Climate](https://codeclimate.com/github/molybdenum-99/infoboxer/badges/gpa.svg)](https://codeclimate.com/github/molybdenum-99/infoboxer)

**Infoboxer** is pure-Ruby Wikipedia (and generic MediaWiki) client and
parser, targeting information extraction (hence the name).

It can be useful in tasks like:

* get a plaintext abstract of an article (paragraphs before first heading);
* get structured data variables from page's **infobox**;
* list page's sections and count paragraphs, images and tables in them;
* convert some huge "comparison table" to data;
* and much, much more!

The whole idea is: you can have any Wikipedia page as a parsed tree with
obvious structure, you can navigate that tree easily, and you have a
bunch of hi-level helpers method, so typical information extraction
tasks should be super-easy, one-liners in best cases.

_(For those already thinking "Why should you do this, we already have
DBPedia?" -- please, read "[Reasons](https://github.com/molybdenum-99/infoboxer/wiki/Reasons)"
page in our wiki.)_

## Showcase

```ruby
Infoboxer.wikipedia.
  get('Breaking Bad (season 1)').
  sections('Episodes').templates(name: 'Episode table').
  fetch('episodes').templates(name: /^Episode list/).
  fetch_hashes('EpisodeNumber', 'EpisodeNumber2', 'Title', 'ShortSummary')
# => [{"EpisodeNumber"=>#<Var(EpisodeNumber): 1>, "EpisodeNumber2"=>#<Var(EpisodeNumber2): 1>, "Title"=>#<Var(Title): Pilot>, "ShortSummary"=>#<Var(ShortSummary): Walter White, a 50-year old che...>},
#     {"EpisodeNumber"=>#<Var(EpisodeNumber): 2>, "EpisodeNumber2"=>#<Var(EpisodeNumber2): 2>, "Title"=>#<Var(Title): Cat's in the Bag...>, "ShortSummary"=>#<Var(ShortSummary): Walt and Jesse try to dispose o...>},
#     ...and so on
```

Do you _feel_ it now?

You also can take a look at [Showcase](https://github.com/molybdenum-99/infoboxer/wiki/Showcase).

## Usage

### Install gem

Install it as usual: `gem 'infoboxer'` in your Gemfile, then `bundle install`.

Or just `[sudo] gem install infoboxer` if you prefer.

### Grab the page

```ruby
# From English Wikipedia
page = Infoboxer.wikipedia.get('Argentina')
# or
page = Infoboxer.wp.get('Argentina')

# From other language Wikipedia:
page = Infoboxer.wikipedia('fr').get('Argentina')

# From any wiki with the same engine:
page = Infoboxer.wiki('http://companywiki.com').get('Our Product')
```

See more examples and options at [Retrieving pages](https://github.com/molybdenum-99/infoboxer/wiki/Retrieving%20pages)

### Play with page

Basically, page is a tree of [Nodes](https://github.com/molybdenum-99/infoboxer/wiki/Nodes), you can think of it as some kind of
[DOM](https://en.wikipedia.org/wiki/Document_Object_Model).

So, you can navigate it:

```ruby
# Simple traversing and inspect
node = page.children.first.children.first
node.to_tree
node.to_text

# Various lookups
page.lookup(:Template, name: /^Infobox/)
```

See [Tree navigation basics](https://github.com/molybdenum-99/infoboxer/wiki/Tree-navigation-basics).

On the top of the basic navigation Infoboxer adds some useful shortcuts
for convenience and brevity, which allows things like this:

```ruby
page.section('Episodes').tables.first
```

See [Navigation shortcuts](https://github.com/molybdenum-99/infoboxer/wiki/Navigation-shortcuts)

To put it all in one piece, also take a look at [Data extraction tips and tricks](https://github.com/molybdenum-99/infoboxer/wiki/Tips-and-tricks).

### infoboxer executable

Just try `infoboxer` command.

Without any options, it starts IRB session with infoboxer required and
included into main namespace.

With `-w` option, it provides a shortcut to MediaWiki instance you want.
Like this:

```
$ infoboxer -w https://en.wikipedia.org/w/api.php
> get('Argentina')
 => #<Page(title: "Argentina", url: "https://en.wikipedia.org/wiki/Argentina"): ....
```

You can also use shortcuts like `infoboxer -w wikipedia` for common
wikies (and, just for fun, `infoboxer -wikipedia` also).

## Advanced topics

* [Reasons](https://github.com/molybdenum-99/infoboxer/wiki/Reasons) for
  Infoboxer creation;
* [Parsing quality](https://github.com/molybdenum-99/infoboxer/wiki/Parsing-quality)
  (TL;DR: very good, but not ideal);
* [Performance](https://github.com/molybdenum-99/infoboxer/wiki/Performance)
  (TL;DR: 0.1-0.4 sec for parsing hugest pages);
* [Localization](https://github.com/molybdenum-99/infoboxer/wiki/Localization)
  (TL;DR: For now, you'll need some work to use Infoboxer's
  most advanced features with non-English or non-WikiMedia wikis; basic
  and mid-level features work always);
* If you plan to use Wikipedia or sister projects data in production,
  please consider [Wikipedia terms and conditions](https://github.com/molybdenum-99/infoboxer/wiki/Wikipedia-terms-and-conditions).

## Compatibility

As of now, Infoboxer reported to be compatible with any MRI Ruby since 1.9.3.
In Travis-CI tests, JRuby is failing due to bug in old Java 7/Java 8 SSL
certificate support ([see here](https://github.com/jruby/jruby/issues/2599)),
and Rubinius failing 3 specs of 500 by mystery, which is uninvestigated yet.

Therefore, those Ruby versions are excluded from Travis config, though,
they may still work for you.

## Links

* [Wiki](https://github.com/molybdenum-99/infoboxer/wiki)
* [API Docs](http://www.rubydoc.info/gems/infoboxer)
  * **NB**: ↑ this is "current version" link, but RubyDoc.info unfortunately
    sometimes fails to update it to really _current_; in case you feel
    something seriously underdocumented, please-please look at
    [0.1.2 docs](http://www.rubydoc.info/gems/infoboxer/0.1.2).
* [Contributing](https://github.com/molybdenum-99/infoboxer/wiki/Contributing)
* [Roadmap](https://github.com/molybdenum-99/infoboxer/wiki/Roadmap)

## License

MIT.
