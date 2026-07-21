/* Coverage for NSTableHeaderCell: the defaults set up by -initTextCell:
   (its classic centred, bezeled, background-drawing header appearance), the
   string value, the highlight handling, and the sort-indicator rectangle,
   which is placed at the right of the bounds.  The cell uses the theme and
   the font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSText.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableHeaderCell *cell;

  START_SET("NSTableHeaderCell")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSTableHeaderCell alloc] initTextCell: @"Col"]);

  /* Defaults. */
  pass([cell alignment] == NSCenterTextAlignment, "the header title is centred");
  pass([cell drawsBackground] == YES, "the header draws its background");
  pass([cell isBezeled] == YES, "the header is bezeled");
  pass([cell isBordered] == NO, "the header is not bordered");
  pass([cell wraps] == NO, "the header title does not wrap");
  pass([[cell stringValue] isEqualToString: @"Col"], "initTextCell: sets the title");
  pass([cell font] != nil, "the header has a font");
  pass([cell textColor] != nil, "the header has a text colour");
  pass([[cell backgroundColor] isEqual: [NSColor controlShadowColor]],
       "the default background is the control shadow colour");

  /* The sort-indicator rectangle sits at the right of the bounds. */
  {
    NSRect bounds = NSMakeRect(10.0, 5.0, 100.0, 20.0);
    NSRect rect = [cell sortIndicatorRectForBounds: bounds];
    NSSize indicator = [[NSImage imageNamed: @"NSAscendingSortIndicator"] size];

    pass(NSMaxX(rect) == NSMaxX(bounds), "the sort indicator is at the right edge");
    pass(rect.origin.y == bounds.origin.y, "the sort indicator keeps the y origin");
    pass(NSEqualSizes(rect.size, indicator),
      "the sort indicator rect has the indicator image size");
  }

  /* Highlighting flips the flag and swaps the background colour. */
  [cell setHighlighted: YES];
  pass([cell isHighlighted] == YES, "setHighlighted: YES sets the highlight");
  pass([[cell backgroundColor] isEqual: [NSColor controlHighlightColor]],
       "highlighting uses the control highlight colour");
  [cell setHighlighted: NO];
  pass([cell isHighlighted] == NO, "setHighlighted: NO clears the highlight");
  pass([[cell backgroundColor] isEqual: [NSColor controlShadowColor]],
       "clearing the highlight restores the control shadow colour");

  END_SET("NSTableHeaderCell")

  DESTROY(arp);
  return 0;
}
