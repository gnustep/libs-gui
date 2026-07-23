/* A combo box shows five items by default (matching AppKit), and
   -setNumberOfVisibleItems: stores any positive count.  The setter used to
   ignore counts of ten or fewer.  Checked against AppKit on a macOS runner.
   The combo box uses the theme and font backend, so the set is skipped when
   the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSComboBox.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSComboBox *cb;

  START_SET("NSComboBox visible items")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NS_DURING
    {
      cb = AUTORELEASE([[NSComboBox alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 22)]);

      PASS([cb numberOfVisibleItems] == 5,
           "the default number of visible items is five");

      [cb setNumberOfVisibleItems: 8];
      PASS([cb numberOfVisibleItems] == 8,
           "a count of eight is stored");

      [cb setNumberOfVisibleItems: 12];
      PASS([cb numberOfVisibleItems] == 12,
           "a count above ten is stored");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSComboBox visible items")

  DESTROY(arp);
  return 0;
}
