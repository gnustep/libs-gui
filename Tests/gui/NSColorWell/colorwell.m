/* Coverage for NSColorWell state: the defaults that match AppKit (not active,
   bordered, a non-nil colour), the bordered round-trip and the colour
   round-trip.  activate: is not exercised, as it drives the shared colour
   panel.  Checked against AppKit on a macOS runner.  The well uses the theme
   and font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSColorWell *cw;

  START_SET("NSColorWell state")

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

  NS_DURING
    {
      cw = AUTORELEASE([[NSColorWell alloc]
        initWithFrame: NSMakeRect(0, 0, 40, 40)]);

      /* Defaults. */
      PASS([cw isActive] == NO, "a color well is not active by default");
      PASS([cw isBordered] == YES, "a color well is bordered by default");
      PASS([cw color] != nil, "a color well has a colour by default");

      /* Round-trips. */
      [cw setBordered: NO];
      PASS([cw isBordered] == NO, "setBordered: round trips");

      [cw setColor: [NSColor redColor]];
      NSColor *c = [[cw color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      PASS(c != nil
           && [c redComponent] > 0.9
           && [c greenComponent] < 0.1
           && [c blueComponent] < 0.1,
           "setColor: keeps the red colour");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSColorWell state")

  DESTROY(arp);
  return 0;
}
