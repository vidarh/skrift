
# Skrift

Vidar Hokstad <vidar@hokstad.com>

This started out as a Ruby port of `libschrift`. If you need
performance, and don't mind a C dependency, consider that over this.

If you're fine with slower rendering (*cache* glyphs after rendering)
and want *pure Ruby*, consider this gem, with the caveat that the
rewrite is *new* and likely buggy.

## Name

"Skrift" is Norwegian for "text", "writing", or "scripture", and so a
close cognate of "Schrift". Since I'm Norwegian, it seemed like an
appropriate way to set this apart from `libschrift` and ensure that if
anyone want to do a gem directly wrapping the C librarly the name remains
available.

## License

While it's rewritten in Ruby and changed reasonably since, given it owes
so much to `libschrift`, I decided to stick with the same license (the
ISC License), since it's very permissive. See `LICENSE.md`

## This code is opinionated

Firstly, the choice to start by rewriting `libschrift` is because that
library is an excellent demonstration of a minimalist feature set and
compact code that I wanted.

However, on top of the structure inherited largely from `libschrift`,
while working on this code, I've formed my own opinions on it which
applies to *this library*, and which the author of `libschrift` may or
may not agree with. These are *my responsibility*:

* Small code size is a virtue as long as it improves rather than hinders
  understanding. Any feature will be weighed against complexity cost.

* Features that add a lot of complexity may be better written as a
  separate library (I will happily work with you to ensure it's easy for
  users to combine your library with `Skrift`)

* Hinting is predominantly important with low resolution. With the trend
  firmly being towards 4K or 8K displays, putting a lot of effort into
  hinting is pointless. I will *consider* hinting if someone wants to
  contribute hinting code, but not at the cost of a lot of complexity (
  unless you build it as a standalone extension)
  
* The current algo uses anti-aliasing. I will *consider* adding support
  for monochrome rendering for the same reason as above, but currently, AA
  is still *necessary* for best possible results at small sizes, at least
  on FHD displays, so since it's already here, I'll *keep* the AA
  support as long as lower resolution displays are still around.
  
* Feature "completeness" for the sake of completeness are not of interest.
  E.g. I have no interest in parsing the parts of the TTF or OTF formats
  this library won't use (but if you write a *compact*, well written
  TTF/ OTF parser in pure Ruby, I *might* consider tearing out the
  font parsing from this gem if using yours simplifies the `Skrift` code)
  
* Idiomatic Ruby is favoured over maximising efficiency (but
  pathologically low performance is not good - I'm open to changes)

* Lowering coupling is favoured (be it for testing, or ease of improving
  the code), but architecture acrobatics should be avoided. That is,
  make it *possible* to test or use individual stages of the rendering
  pipeline, but don't force library users to care - setup should be
  minimal, and defaults sane. Factories and abstract interfaces should
  stay in Java or be used to scare small children, not be found in
  Ruby code.

  
## Contributions and Potential Improvements

Contributions are welcome, keeping the above in mind. If your
contributions are potentially unrelated to the specific purpose of this
library, I might propose you put them in a separate gem instead, and
might then offer to help create easy integration points so your code can
safely extent this library if a user chooses to use both.

Some possible areas for extension, and my current thoughts on them
(*talk to me* if you want to work on something)

### X11 or Wayland (or Windows, or Mac) integration

No.

I will happily ensure there necessary APIs are there so that you can
*wrap* or integrate with `Skrift`, or so that you can render to something
that makes it convenient. E.g. the current rendering to 8 bit
greyscale already makes `Skrift` (thanks to `libschrift` doing this from
the start) integrate easily with `XRender` for X11 support.

I will not, however, put platform specific code in `Skrift` itself (I
*will* accept code well-written code to make use of "platform specific"
data *from the font files*, however, because they can be useful on other
platforms)

I use this code for rendering to `X11` myself. It does not require
pushing platform specific code into this library.


### Performance

Performance improvements are welcome *but not if they add a lot of
complexity*. C-extensions or similar will not be accepted - if you
want a C dependency, just use `libschrift`.

If you have a suggestion that involves using C in a limited way to speed
up specifics, I'd suggest providing a *separate* gem to replace/extend
the appropriate code the same way `oily_png` provides code to speed up
`chunky_png`. I'm happy to discuss specifics.

### Grid snapping

Where I'm *most likely* to consider a hinter is a *limited* hinter
to dynamically rescale glyphs to allow using a variable spaced font
snapped to a grid for e.g. terminal use in a somewhat intelligent way (I
don't expect this is likely to look good, but I'm open to be convinced
even if it only works on some fonts, though it might well be better as a
standalone conversion tool unless it works well on a broad range of
fonts)

### Transformations

The current code already applies linear affine transformations to the
glyphs. I'd be supportive of *compact* contributions to make it easier to
apply a broader set of transforms during rendering to allow for more
flexible layout. Please discuss API first if you want anything merged, or
if you just want stable extension points to do this in a separate
library.

### Outlines

You can currently extract outlines, and so can of course replace the
rendering stage and render unfilled outlines on your own. That said, I'd
be supportive both of low complexity changes to render the fonts as
outlines *and* of low complexity changes to "grow" outlines (e.g. to
be able to render an outline in one colour and a filled version in the
desired size in another colour - you can't do this by just scaling). The
code that'd need to change to replace the rasteriser is tiny.

### Text Layout

Specifically, *text layout* is perhaps out of scope of this library, but
I'm happy to discuss it - if nothing else I'd be supportive of an
extension in a separate gem and/or ensuring the basics is well
supported.
