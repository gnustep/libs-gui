/* NSTextView default flags that match AppKit: a new text view accepts glyph
   info and does not allow the document background colour to be changed. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTextView *tv;

  START_SET("NSTextView defaults")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  tv = AUTORELEASE([[NSTextView alloc]
    initWithFrame: NSMakeRect(0, 0, 300, 200)]);

  PASS([tv acceptsGlyphInfo] == YES, "default acceptsGlyphInfo is YES");
  PASS([tv allowsDocumentBackgroundColorChange] == NO,
       "default allowsDocumentBackgroundColorChange is NO");

  END_SET("NSTextView defaults")

  DESTROY(arp);
  return 0;
}
