#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSOpenPanel.h>

/* An open panel lets the user choose files but not directories by default
   (checked against AppKit); it defaulted to allowing directories.  Creating the
   panel needs a backend, so this keeps the usual guard. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSOpenPanel canChooseDirectories default")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSOpenPanel *p = [NSOpenPanel openPanel];

      PASS([p canChooseFiles] == YES, "canChooseFiles defaults to YES");
      PASS([p canChooseDirectories] == NO,
        "canChooseDirectories defaults to NO");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOpenPanel canChooseDirectories default")
  DESTROY(arp);
  return 0;
}
