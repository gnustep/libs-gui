/* NSTabView stores the control size and control tint: the defaults are the
   regular size and the default tint, and both round-trip once set. Checked
   against AppKit on a macOS runner. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTabView *tv;

  START_SET("NSTabView controlSizeTint")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      tv = AUTORELEASE([[NSTabView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 150)]);

      pass([tv controlSize] == NSRegularControlSize,
           "the default control size is regular");
      pass([tv controlTint] == NSDefaultControlTint,
           "the default control tint is the default tint");

      [tv setControlSize: NSSmallControlSize];
      pass([tv controlSize] == NSSmallControlSize, "controlSize round-trips");
      [tv setControlTint: NSBlueControlTint];
      pass([tv controlTint] == NSBlueControlTint, "controlTint round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabView controlSizeTint")

  DESTROY(arp);
  return 0;
}
