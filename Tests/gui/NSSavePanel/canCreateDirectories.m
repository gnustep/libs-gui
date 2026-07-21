#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSSavePanel.h>

/* A save panel offers to create directories by default (checked against
   AppKit); it defaulted to not offering that.  Creating the panel needs a
   backend, so this keeps the usual guard. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSavePanel canCreateDirectories default")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSavePanel *p = [NSSavePanel savePanel];

      PASS([p canCreateDirectories] == YES,
        "canCreateDirectories defaults to YES");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSavePanel canCreateDirectories default")
  DESTROY(arp);
  return 0;
}
