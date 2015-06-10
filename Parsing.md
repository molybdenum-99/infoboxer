Parsing Wikipedia is not an easy tasks. Some tags and formattings signs
can be only after newline, some can be everywhere in text; some formatting
can span several lines, some is force-closed on line end; there can be
tons and tons of markup inside image captions, templates and <ref>'s, so...
Here's what I've came with:

1. Entire page text is split into lines (after replacing of `<!-- -->`
  comments -- they go nowhere).
2. First, we are in *paragraph* context. We are looking at next line in
  list and guessing what it is: list, heading and so on
3. Then, we are in *inline* context for text of paragraph (unless it is
  table, which is different story, and headings, which also different,
  and of course preformatted text,... you've got the idea). We scan text
  until *any* of inline formatting will be met (or end of line).
4. When met with some formatting, we push current context and scan inside
  it. The inline scanning is tricky!
  * Simple formatting like `''` (italic) is implicitly closed at the end
    of line (it is called "short inline scan" inside Infoboxer's parser)
  * Long formatting like templates can span several lines, so we continue
    scan through next lines, till template end (it means we are still in
    same paragraph!), it's "normal inline scan", or just "inline scan"
  * Some __inline__ formatting (like <ref>'s) and special formatting,
    like table cells, can have other paragraphs inside! (But it's still
    "inline" formatting, because when <ref> is ended, the same paragraph
    is continued -- while showing it in Wikipedia, ref will leave a small
    footnote mark in paragraph, and the contents will be below). We call
    such a cases "long inline scan".
5. So, parser tries to do everything in one forward scan, without returning
  to previous positions or tricks like "scan all symbols till the end of
  template, then parse them as a separate sub-document" (the letter is
  the simplest way to parse MediaWiki markup; that's how Infoboxer worked
  at first; it was not very fast and not memory-effective at all).
  
