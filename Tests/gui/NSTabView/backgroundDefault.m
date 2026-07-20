/* A default NSTabView draws its background and allows truncated labels, as
   AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTabView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTabView *tv;

  START_SET("NSTabView backgroundDefault")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      tv = AUTORELEASE([[NSTabView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      pass([tv drawsBackground] == YES,
           "a new tab view draws its background");
      pass([tv allowsTruncatedLabels] == YES,
           "a new tab view allows truncated labels");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabView backgroundDefault")

  DESTROY(arp);
  return 0;
}
