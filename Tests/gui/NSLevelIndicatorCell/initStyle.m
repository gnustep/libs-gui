/* A default NSLevelIndicatorCell uses the discrete-capacity style, as AppKit
   does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSLevelIndicatorCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSLevelIndicatorCell *cell;

  START_SET("NSLevelIndicatorCell initStyle")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSLevelIndicatorCell alloc] init]);
  pass([cell style] == NSDiscreteCapacityLevelIndicatorStyle,
       "a default level indicator cell uses the discrete-capacity style");

  END_SET("NSLevelIndicatorCell initStyle")

  DESTROY(arp);
  return 0;
}
