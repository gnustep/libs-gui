/* NSGlyphInfo name and deprecated-glyph factories.  The name factory resolves
   the glyph name in the font: a name the font does not provide, or a nil font,
   gives nil; a name it provides gives an object whose glyphName is that name.
   The deprecated glyph factory wraps a glyph.  Behaviour checked against AppKit
   on a macOS runner.  The set is skipped when the font backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSGlyphInfo.h>

/* Find an installed font that resolves a glyph name (the backend needs a font
   carrying PostScript glyph names).  Returns the font and fills *outName with a
   name it provides, or nil when none is available. */
static NSFont *
fontThatNamesGlyphs(NSString **outName)
{
  static const char * const names[] = { "A", "space", "period", "zero", "a" };
  NSArray *available = [[NSFontManager sharedFontManager] availableFonts];
  NSUInteger i, j;

  for (i = 0; i < [available count]; i++)
    {
      NSFont *f = [NSFont fontWithName: [available objectAtIndex: i] size: 12];

      if (f == nil)
        continue;
      for (j = 0; j < sizeof(names) / sizeof(names[0]); j++)
        {
          NSString *n = [NSString stringWithUTF8String: names[j]];

          if ([f glyphWithName: n] != NSNullGlyph)
            {
              *outName = n;
              return f;
            }
        }
    }
  return nil;
}

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSGlyphInfo *g;
  NSFont *font;
  NSFont *namedFont;
  NSString *aName = nil;

  START_SET("NSGlyphInfo name factory")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  font = [NSFont systemFontOfSize: 12];

  PASS([NSGlyphInfo glyphInfoWithGlyphName: @"A"
                                   forFont: nil
                                baseString: @"A"] == nil,
       "the name factory returns nil without a font");

  PASS([NSGlyphInfo glyphInfoWithGlyphName: @"NotAGlyphNameInAnyFont__"
                                   forFont: font
                                baseString: @"A"] == nil,
       "the name factory returns nil for a name the font does not provide");

  /* The deprecated glyph factory wraps a glyph and is never nil. */
  g = [NSGlyphInfo glyphInfoWithGlyph: 36 forFont: font baseString: @"A"];
  PASS(g != nil, "the deprecated glyph factory returns an object");
  PASS([g glyphID] == 36, "the deprecated glyph factory keeps the glyph");
  PASS([[g baseString] isEqualToString: @"A"],
       "the deprecated glyph factory keeps the base string");

  /* The positive path depends on a font providing PostScript glyph names; skip
     it where the backend has no such font installed. */
  namedFont = fontThatNamesGlyphs(&aName);
  if (namedFont != nil)
    {
      g = [NSGlyphInfo glyphInfoWithGlyphName: aName
                                     forFont: namedFont
                                  baseString: @"x"];
      PASS(g != nil, "the name factory returns an object for a provided name");
      PASS([[g glyphName] isEqualToString: aName],
           "the name factory records the glyph name");
      PASS([[g baseString] isEqualToString: @"x"],
           "the name factory keeps the base string");
    }
  else
    {
      SKIP("no installed font provides PostScript glyph names")
    }

  END_SET("NSGlyphInfo name factory")

  DESTROY(arp);
  return 0;
}
