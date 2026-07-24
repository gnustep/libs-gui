/* A colour panel shows the alpha (opacity) control by default, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColorPanel.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSColorPanel showsAlpha")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  PASS([[NSColorPanel sharedColorPanel] showsAlpha] == YES,
       "a colour panel shows the alpha control by default");

  END_SET("NSColorPanel showsAlpha")

  DESTROY(arp);
  return 0;
}
