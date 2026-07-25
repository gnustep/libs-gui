#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSOpenPanel.h>

/* State defaults and round-trips specific to NSOpenPanel (the shared save-panel
   state is covered under NSSavePanel).  Default values checked against AppKit;
   canChooseDirectories, which AppKit defaults differently, is handled
   separately and is not pinned here.  Needs a backend, so it keeps the guard. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSOpenPanel config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSOpenPanel *p = [NSOpenPanel openPanel];

      /* defaults that match AppKit */
      PASS([p canChooseFiles] == YES, "canChooseFiles defaults to YES");
      PASS([p allowsMultipleSelection] == NO,
        "allowsMultipleSelection defaults to NO");
      PASS([p resolvesAliases] == YES, "resolvesAliases defaults to YES");

      /* round-trips */
      [p setCanChooseFiles: NO];
      PASS([p canChooseFiles] == NO, "setCanChooseFiles: round-trips");
      [p setCanChooseDirectories: NO];
      PASS([p canChooseDirectories] == NO,
        "setCanChooseDirectories: round-trips");
      [p setAllowsMultipleSelection: YES];
      PASS([p allowsMultipleSelection] == YES,
        "setAllowsMultipleSelection: round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOpenPanel config")
  DESTROY(arp);
  return 0;
}
