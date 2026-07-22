/* A new NSColorWell starts with a white colour, matching AppKit (it was
   black).  Checked against AppKit on a macOS runner.  The well uses the theme
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

  START_SET("NSColorWell default colour")

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

      NSColor *c = [[cw color] colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      PASS(c != nil
           && [c redComponent] > 0.9
           && [c greenComponent] > 0.9
           && [c blueComponent] > 0.9,
           "the default colour is white");
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

  END_SET("NSColorWell default colour")

  DESTROY(arp);
  return 0;
}
