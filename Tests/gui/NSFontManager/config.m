/* Coverage for the shared NSFontManager: the singleton, its default state and
 * the selected-font round-trip.  Building the shared manager creates the font
 * enumerator, so the test is guarded and skips cleanly when no backend is
 * available.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("shared font manager")

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

      PASS(fm != nil, "sharedFontManager returns a manager");
      PASS(fm == [NSFontManager sharedFontManager],
        "sharedFontManager is a singleton");
      PASS([fm isMultiple] == NO, "the manager is not multiple by default");
      PASS(sel_isEqual([fm action], @selector(changeFont:)),
        "the default action is changeFont:");
      PASS([fm selectedFont] == nil, "there is no selected font by default");
      PASS([fm delegate] == nil, "there is no delegate by default");

      {
        NSFont *f = [NSFont fontWithName: @"Helvetica" size: 18.0];

        [fm setSelectedFont: f isMultiple: YES];
        PASS([fm selectedFont] == f, "the selected font round-trips");
        PASS([fm isMultiple] == YES, "the multiple flag is set");
        [fm setSelectedFont: f isMultiple: NO];
        PASS([fm isMultiple] == NO, "the multiple flag clears");
      }
    }
  NS_HANDLER
    SKIP("No font backend available for the font manager")
  NS_ENDHANDLER

  END_SET("shared font manager")
  DESTROY(arp);
  return 0;
}
