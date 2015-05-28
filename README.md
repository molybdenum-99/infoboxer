**Infoboxer** is pure-Ruby Wikipedia client and parser, targeting
information extraction (hence the name).

It can help you in tasks like:

* get a plaintext abstract of an article (paragraphs before first heading);
* get value of some parameter in page's *infobox*;
* list page's sections and count paragraphs, images and tables in them;
* convert some huge "comparison table" to data;
* and much, much more!

The whole idea is: you can have any Wikipedia page as a parsed tree with
obvious structure, you can navigate that tree easily, and you have a
bunch of hi-level helpers method, so typical information extraction
tasks should be super-easy, one-liners in best cases.

*(For those already thinkind "Why should you do this, we already have
DBPedia?" -- please, read "[Reasons](#reasons)" section below.)*

## OK, show me some code!

Easy.

```ruby
page = Infoboxer.get('Argentina')

puts page.intro.text

puts page.categories.join(', ')

puts page.infobox.area_km2

page.sections.each do |sec|
  puts "#{sec}: #{sec.paragraphs.count} paragraphs"
end
```

Do you ''feel'' it now?

## Getting Started

Install it as usual: `gem 'infoboxer'` in your Gemfile, then `bundle install`.

Or just `[sudo] gem install infoboxer` if you prefer.

### Retrieving the page

```ruby
# from Wikipedia API:
page = Infoboxer.get('Argentina')

# or from saved text:
page = Infoboxer::Parser.parse(File.read('argentina.wiki'))

# you can even have several pages from API:
pages = Infoboxer.get('Argentina', 'Chile', 'Bolivia')
```

### Hacking the parse tree

The page basically contains a parsing tree of all *nodes*. You can see
it like this:

```ruby
puts page.to_tree
```

(CAUTION: for typical Wikipedia page it can easily produce tens of
thousands of lines!)

The content model of the tree tries to be straightforward, not very deep
and easily understandable:
* on the first level there's paragraphs, headings, lists and tables;
* inside them is inline markup: bolds and italics, links, images, templates
  and allowed HTML tags;
* each tree node type has its own class with obvious name: Infoboxer::Paragraph,
  Infoboxer::Heading, Infoboxer::UnorderedList and so on.

Basic node methods:
* `Node#text` -- text of node and all of it children
* `Node#children` -- list of node children
* `Node#parent` -- node parent
* `Node#to_tree` -- pretty output of node and all of its chidren as a tree

Tree navigation is done like this:

```ruby
# Node#lookup
page.lookup(Wikilink) # all wikilinks on page
page.lookup(Heading, level: 3) # all headings of level 3 only
page.lookup(Wikilink){|l| l.text.include?('federation')}

# Node#lookup_child
page.lookup(Paragraph).first.lookup_child(Italic)
# => only italics which are direct children of the para (doesn't returns
#    italics inside links, for example)

# Node#lookup_parent
page.lookup(ListItem).first.lookup_parent(UnorderedList)
```

Each lookup returns special `Nodes` type - which is `Array` with some
useful extensions:

1. `Nodes#text` gives you joined string of all nodes inside (strings are
   joined smartly, so you'll have paragraphs separated with `"\n"` and
   inlines joined;
2. `Nodes#lookup_*` methods are the same as for individual node, so you
   can just continue your navigation like:

```ruby
page.lookup(UnorderedList).lookup_children(text: /wtf\?/)
```

It's not an XPath-strength solution, yet it is straightforward and powerful
enough (and it is pure Ruby).

Surprisingly, that's enough power to get virtually everything Wikipedia
can provide. Yet there's more!

### Tastier Things

#### Simple Shortcuts

* `Page#paragraphs` - all paragraph-level nodes (plain paragraphs, list
  items, headings, pre-formatted lines - but not tables, templates or lists)
* `Page#wikilinks`, `Page#external_links`, `Page#images`, `Page#tables`,
  `Page#templates` -- pretty self-explanatory
* Same methods are available in any node, so you can do something like
  `page.paragraphs.first.wikilinks` easily
* `Node#bold?`, `Node#italic?`, `Node#heading?` and `Node#heading?(level)`
  are checks if current node **inside** named formatting. Use it like
  `page.wikilinks.select(&:bold?)` -- only bold, significant links!
* Any more ideas? Drop me a line! (Or pull request ;)

#### Document Sections

"Flat" document model (heading, then paragraph, then another heading) is
responds to Wikipedia structure (and to HTML), but it's not semantic enough!

So, here are sections:

```ruby
page.intro # paragraphs before first heading
page.sections # top-level document sections, made of heading and nodes
              # before next heading of same level

sec = page.sections.first
sec.heading # => <Heading(level=2)....>
sec.body # => all nodes in section
```

You can also make use of:
* `#paragraphs`, `#images` and so on -- just like for document itself;
* even `Section#intro` and `Section#sections` -- for next-level section
  navigation (heading 3 and so on).

If you know which section do you need, just use:

```ruby
# section named "Culture"
page.section('Culture')

# section "Visual arts" inside "Culture"
page.section('Culture').section('Visual arts')
# or just
page.section('Culture', 'Visual arts')
```

**Gotcha**: sections are "virtual" nodes, they are NOT in a tree. So, you may
be surprised with:

```ruby
page.lookup(Section)
# => []
section = page.sections.first
# => <Section...>
section.paragraphs.first.lookup_parent(Section)
# => []
section.paragraphs.first.parent
# => <Page....>

# but there IS Node#section for each node:
section.paragraphs.first.section
# => <Section...>
# or
section.paragraphs.first.section(3)
# => section of level 3, if paragraph is inside it
```

#### Fun with links

Many things in Wikipedia are based on **links**, especially internal ones
(named [Wikilinks](http://www.mediawiki.org/wiki/Help:Links#Internal_links)).
Infoboxer is pretty good with them.

For single link, you have:
* `#caption` -- link title (for `[[Albert Einstein]]` it will return
  "Albert Einstein", for `[[Albert Einstein|Einstein]]` it would be
  "Einstein";
* `#link` -- raw value of link name, "Albert Einstein for latter example;
* `#namespace`, `#name`, `#anchor`: for link like
  `[[Category:Countries#See also]]` it would return 'Category',
  'Countries', 'See also', respectively
* `#topic` -- it's like page name, but without some "refinement"
  part. For "Phoenix, Arizona" it will be "Phoenix", for "Pipe (computing)"
  just "Pipe" (and there would be `#refinement`, returning 'Arizona' and
  'computing' respectively)
  * Use carefully! It will not always produce the expected effect: for ex.,
    page title about film "Me, Myself and Irene" will be splitted in topic
    "Me" and refinement "Myself and Irene"
* `#url` -- full url to linked page for opening in browser
* `#follow` -- will ask wikipedia API and return you linked page, already
  parsed!

For links in document (or inside any other node, containing links), you
have:
* `#wikilinks` -- return array (`Nodes`-wrapped one) of `Wikilink`, but
  only those **without any namespace**;
* `#wikilinks('Namespace')` or `#wikilinks('Namespace:')` will give you
  all links within namespace, and `#wikilinks(nil)` -- all links in all
  the namespaces;
* `#categories` -- is list of categories document belongs to. In fact,
  it just a shortcut for `#wikilinks('Category')`.

**NB**: the latter works ONLY for English-language wikis, see "Localization"
section for details.

#### Infoboxes, Finally!

TODO

#### Some Experimental Things

It's rather draft of future API, then production-ready API, though, you
can do this:

```ruby
pp Infoboxer.wikipedia.get('Porsche 991').
  section('Engines','Performance').
  tables.first.to_hashes
```

### More about templates

Templates in Wikipedia pages can be extremely useful (like infoboxes are),
but in some cases they obscure the content. For example, there are
templates like "{{columns|2|...contents}}" which just renders contents
inside it in two columns -- but while parsing the page, we can't tell
"just wrapping the content kind of template from "producing different
content" ones.

Because of this, Infoboxer treats templates as "special node with some
content", not a "node with children" node. Therefore, when you do document
tree navigation, you will NOT be navigated inside template (so, code
like `page.wikilinks` will not return links inside templates). Most of
the time, it is the "least surprise" solution: almost any content analysis
should NOT treat template content "as is".

But when you have a template like aforementioned `{{columns` or even
`{{!}}` (used to output literal symbol "|" in context, where it can have
special meaning), you just loose part of contents inside some "black box".

Infoboxer tries to workaround this by having template
substitution dictionary, which replaces most common "content wrapping"
templates with appropriate contents, but it is still far from complete,
and works, as almost everything about templates, only for English Wikipedia.

### Mastering It All

TODO: read source, view tree, navigate document

### Getting Plain Text

## Reasons

Wikipedia has lots of informations. Some can say, all of world "common"
information (and others can say it is misleading, incomplete, or broken
in any way possible).

TODO: information extraction

### So, why not DBPedia?

[DBPedia](http://dbpedia.org) is a great effort for extracting
data from Wikipedia and store them in structured form, it does a great use
of Semantic Web technologies (RDF, SPARQL), interoperates with existing
ontologies and overall awesome.

But DBPedia also **is**:

* **outdated** -- at a time I'm writing it (May 26, 2015), DBPedia resources,
  accessible online, are from Wikipedia dump of May 02, 2014. Yep, 2014.
  More than year old. Enough for some topics, dramatically outdated for
  others (governments, movies, solar eclypse, births and deaths...);
* **incomplete** (and information is lost unrecoverably) -- DBPedia maps
  only subset of properties and areas of Wikipedia pages, and everything
  left behind that mapping can not be received through DBPedia at all;
* **ambiguous** -- trying to interweave existing ontologies, languages,
  means of representing same properties, DBPedia leaves you with several
  ways to query even the basic properties (like "name" or "type"), and
  any of them can be broken in strange way for very similar page;
* **complicated** -- for querying the simplest data, you should have
  some understanding of Semantic Web technologies -- RDF, triples,
  namespaces, literals representation, sometimes SPARQL...

So, I've tried to implement simpler and cleaner (and also more actual)
way to grab your data.

Still, DBPedia **is** useful for complex (SPARQL) queries, when you need
something like "all Argentinian cities with population more than X, to
the south of Y", which Wikipedia API can not.

## Parsing quality

As for version 0.0.1, Infoboxer implements most of Wikipedia markup.
Most of not implemented markup is rarely used and still would provide
valid and reasonable output (for ex., `<nowiki>` tag will be treated as
"usual" HTML tag, which is nearly OK for most cases), and, anyways, will
be implemented in nearest version.

I've tried the parser on several complex pages and everything was fine.
Maybe in future we need a large and diverse "test dataset" of complicated
pages. But for now, if you'll encounter some bugs or inconsitencies -- just
show them to me.

Still, there may be failures on pages:
* extensively using `<nowiki>` or `<pre>` tags -- Infoboxer will try to
  parse inside this, and results are unpredictable;
* about programming, with many of source code fragments -- same as above;
* template definitions -- most of used there features are not implemented.

Also, really complicated embedded HTML may produce something strange --
but it is not seen on typical Wikipedia page.

Note, that Infoboxer main target is **information extraction from existing
wiki[pedia] articles**. Therefore, it never tries to "parse the markup
anyways": if the markup is seriously inconsistent, the ParseError will be
thrown.

On my thought, it's the most reasonable thing: if you have a page
with very broken markup, it is definitely better not trying to extract
information at all.

The solution, though, have some drawbacks:
* you hardly can use Infoboxer as backend for your own MediaWiki-like
  software: unlike Wikipedia editor, it will not try to "show somehow"
  the strangest markup, it just throw;
* it may be not very useful for some small and marginal MediaWiki-based
  wikis, where nobody monitors and validates markup quality.

There is one exception from "markup should always be valid" rule: inside
templates, markup CAN be invalid, being "only partial". For example:

```
{{some template| some variable''}}
```

Note the only "italic" symbol (`''`) -- its because pairing symbol can
be added on template interpretation. Therefore, for template variables
Infoboxer handles unparseable markup and in those cases returns entire
variable contents as a single `Text` node.

## Performance

It is nor fascinating neither awful. On my small notebook, really large
and full-featured Wikipedia page (like aforementioned
[Argentina](http://en.wikipedia.org/wiki/Argentina)) is parsed in some
0.2-0.4 sec. It's 10k nodes tree, for the record.

It seems enough for hacking/extracting information from several pages,
yet definitely not very good especially if you want something like
"extract data of pages from entire category". Speedup of parser is target
of future releases (even if we should be ready to rewrite crucial parts as
C extension).

## Localization

Core codebase is written in a fashion allowing to use Infoboxer with any
WikiMedia-based engine, including Wikipedia in other languages, wikia.com
projects and much more.

Though, some of "testiest" hi-level navigation features are wiki- and
locale-dependent. For example, `page.categories` is just a selection of
wikilinks in namespace "Category:", which will be named different for
other-language wikis; and each language version of Wikipedia uses different
templates with different logic.

From the very beginning of the project I've been aware of this, so
everything local about different wikis are going into infoboxer/wikis
folder. For now, there's only en.wikipedia.org.rb, but basing on this
file as an example, you can easily (I hope) define your own handlers.
If it would be handlers for Wikipedia in your language -- please, send
it to me as a patch/pull request, it would be really appreciated!

## Wikipedia API limits and terms

When using Infoboxer for massive data extraction from Wikipedia, you
should consider this:

* Before using the data, you should consider
  [Wikipedia's license](http://en.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License).
  [Here](http://en.wikipedia.org/wiki/Wikipedia:Reusing_Wikipedia_content) is
  some explanation of how to properly reuse the content
* There's no official API request limits, and documentation explicitly
  states that
  > If you make your requests in series rather than in parallel
  > (i.e. wait for the one request to finish before sending a new request,
  > such that you're never making more than one request at the same time),
  > then you should definitely be fine."
  > [here](http://www.mediawiki.org/wiki/API:Etiquette#Request_limit)
* Official documentation explicitly requires you to specify User-Agent
  header. Infoboxer provides some default header, but docs say:
  > Don't use the default User-Agent provided by your client library, but
  > make up a custom header that identifies your script or service and
  > provides some type of means of contacting you (e.g., an e-mail address).
  > [here](http://www.mediawiki.org/wiki/API:Main_page#Identifying_your_client)

With Infoboxer, you do the latter like this:

```ruby
UA = 'MyCoolTool/1.1 (http://example.com/MyCoolTool/; MyCoolTool@example.com)'
Infoboxer.user_agent = UA
# now all requests to all wikis will be with your User-Agent

# or, alternatively, just for one target site:
client = Infoboxer.wikipedia(user_agent: ua)
```

## Roadmap

In my head, Infoboxer is already a useful piece of software, but it is
still far from complete. Plan for next versions include (in no particular
order, as of now):

* Implement complex and rare Wikipedia markup parsing;
* Parser refactoring: faithfully, it's not a prettiest code right now;
  but at least it have specs, so it should be pretty easy to refactor;
* Performance optimizations; target performance is at least ~10x faster
  than we have now;
* More hi-level API, especially for info-templates and tables;
* More template substitutions;
* Localizations (need help!);
* Cover more features of Wikipedia API -- at least search and page list
  [generators](http://www.mediawiki.org/wiki/API:Query#Generators)
* Part of previous item: more info about current page from Wikipedia API,
  like real URL's of image files, interwiki links and so on.
