# Infoboxer

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

_(For those already thinkind "Why should you do this, we already have
DBPedia?" -- please, read "[Reasons](https://github.com/molybdenum-99/infoboxer/wiki/Reasons)"
page in our wiki.)_

## Showcase

```ruby
```

Do you _feel_ it now?

You also can take a look at [Showcase](https://github.com/molybdenum-99/infoboxer/wiki/Showcase)
and inspect [examples](https://github.com/molybdenum-99/infoboxer/tree/master/examples) folder.

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
page = Infoboxer.wiki('http://companywiki.com/w/api.php').get('Our Product')
```

See more examples and options at [Retrieving pages](https://github.com/molybdenum-99/infoboxer/wiki/Retrieving%20pages)

### Play with page

Basically, page is a tree of nodes, you can think of it as some kind of
[DOM](https://en.wikipedia.org/wiki/Document_Object_Model).

So, you can navigate it:

```ruby
# Simple traversing and inspect
node = page.children.first.children.first
node.to_tree
node.to_text

# Various lookups
page.lookup(Template, name: /^Infobox/)
```

See [Tree navigation basics].

On the top of the basic navigation Infoboxer adds socalled "semantic"
navigation, which allows things like this:

```ruby
page.section('Episodes').tables.first
```

See [Semantic navigation]

Infoboxer also provides helper methods to some types of the nodes -- most
useful ones from information extraction perspective. See

* [Wikilinks tricks]
* [Templates tricks]
* _Tables tricks_ -- work in progress

To put it all in one piece, also take a look at [Information extraction tips and tricks].

## Advanced topics

* [Reasons] for Infoboxer creation
* [Parsing quality] (TL;DR: very good, but not ideal)
* [Performance] (TL;DR: 0.1-0.4 sec for parsing hugest pages)
* [Localization] (TL;DR: For now, you'll need some work to use Infoboxer's
  most advanced features with non-English or non-WikiMedia wikis; basic
  features work always)
* If you plan to use Wikipedia or sister projects data in production,
  please consider [Wikipedia terms and conditions]

## Links

* [Wiki]
* [API Docs]
* [Gitter]

## Roadmap

## Contributing & Development

## License

MIT.
