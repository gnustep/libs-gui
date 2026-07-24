#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSOpenPanel.h>

/* -resolvesAliases / -setResolvesAliases: were stubs: the setter did nothing
   and the getter always returned YES.  The flag now defaults to YES (checked
   against AppKit) and round-trips.  Needs a backend, so it keeps the guard. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSOpenPanel resolvesAliases")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSOpenPanel *p = [NSOpenPanel openPanel];

      PASS([p resolvesAliases] == YES, "resolvesAliases defaults to YES");

      [p setResolvesAliases: NO];
      PASS([p resolvesAliases] == NO, "setResolvesAliases: NO round-trips");
      [p setResolvesAliases: YES];
      PASS([p resolvesAliases] == YES, "setResolvesAliases: YES round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOpenPanel resolvesAliases")
  DESTROY(arp);
  return 0;
}
