#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSString.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSSavePanel.h>

/* -message / -setMessage: were stubs: the setter did nothing and the getter
   returned nil.  The message now defaults to an empty string (checked against
   AppKit) and round-trips.  Needs a backend, so it keeps the guard. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSavePanel message")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSavePanel *p = [NSSavePanel savePanel];

      PASS([[p message] isEqual: @""], "message defaults to an empty string");

      [p setMessage: @"Choose a destination"];
      PASS([[p message] isEqual: @"Choose a destination"],
        "setMessage: round-trips");

      [p setMessage: @""];
      PASS([[p message] isEqual: @""], "setMessage: with an empty string clears it");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSavePanel message")
  DESTROY(arp);
  return 0;
}
