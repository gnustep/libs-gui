#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSColorPanel.h>

/* The shared color panel sends continuous action messages by default.  Building
   it needs a window server, so the set skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSColorPanel continuous")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSColorPanel *cp = [NSColorPanel sharedColorPanel];

      PASS([cp isContinuous] == YES,
        "the shared color panel is continuous by default");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSColorPanel continuous")
  DESTROY(arp);
  return 0;
}
