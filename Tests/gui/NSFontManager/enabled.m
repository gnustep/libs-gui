/* Regression test: the shared font manager is enabled by default and the
 * enabled state round-trips through -setEnabled: without requiring a font panel
 * to have been created.  Building the shared manager needs the backend, so the
 * test is guarded and skips cleanly when none is present.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFontManager.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("font manager enabled state")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("It looks like the GNUstep backend is not available")
  NS_ENDHANDLER

  NS_DURING
    {
      NSFontManager *fm = [NSFontManager sharedFontManager];

      PASS([fm isEnabled] == YES, "the font manager is enabled by default");
      [fm setEnabled: NO];
      PASS([fm isEnabled] == NO, "setEnabled: NO disables the manager");
      [fm setEnabled: YES];
      PASS([fm isEnabled] == YES, "setEnabled: YES re-enables the manager");
    }
  NS_HANDLER
    SKIP("No font backend available for the font manager")
  NS_ENDHANDLER

  END_SET("font manager enabled state")
  DESTROY(arp);
  return 0;
}
