/* Coverage for NSGlyphInfo: the character-identifier factory and its readonly
   accessors (characterIdentifier, characterCollection, baseString, glyphName)
   and the CG-glyph factory's baseString.  Every assertion here matches AppKit
   (verified on a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGlyphInfo.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSGlyphInfo *g;
  NSFont *font;

  START_SET("NSGlyphInfo basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* the character-identifier factory */
  g = [NSGlyphInfo glyphInfoWithCharacterIdentifier: 42
                                         collection: NSAdobeJapan1CharacterCollection
                                         baseString: @"X"];
  pass(g != nil, "the character-identifier factory returns an object");
  pass([g characterIdentifier] == 42, "characterIdentifier is the value passed in");
  pass([g characterCollection] == NSAdobeJapan1CharacterCollection,
       "characterCollection is the collection passed in");
  pass([[g baseString] isEqualToString: @"X"], "baseString is the string passed in");
  pass([g glyphName] == nil,
       "glyphName is nil for a character-identifier glyph info");

  /* the CG-glyph factory */
  font = [NSFont systemFontOfSize: 12];
  g = [NSGlyphInfo glyphInfoWithCGGlyph: 36 forFont: font baseString: @"A"];
  pass(g != nil, "the CG-glyph factory returns an object");
  pass([[g baseString] isEqualToString: @"A"],
       "baseString is the string passed in for a CG-glyph info");

  END_SET("NSGlyphInfo basic")

  DESTROY(arp);
  return 0;
}
