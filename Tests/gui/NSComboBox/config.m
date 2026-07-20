/* Coverage for the NSComboBox configuration: the defaults that match AppKit
   (internal list mode, a vertical scroller, no completion, a bordered button,
   no items and no selection) and the setter round-trips.  Checked against
   AppKit on a macOS runner.  The combo box uses the theme and font backend,
   so the set is skipped when the backend is unavailable.
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

  START_SET("NSComboBox config")

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

      /* Defaults. */
      pass([cb usesDataSource] == NO,
           "a combo box uses its internal list by default");
      pass([cb hasVerticalScroller] == YES,
           "a combo box has a vertical scroller by default");
      pass([cb completes] == NO, "completion is off by default");
      pass([cb isButtonBordered] == YES, "the button is bordered by default");
      pass([cb numberOfItems] == 0, "a new combo box has no items");
      pass([cb indexOfSelectedItem] == -1, "nothing is selected by default");

      /* Setter round-trips. */
      [cb setHasVerticalScroller: NO];
      pass([cb hasVerticalScroller] == NO, "setHasVerticalScroller: round trips");
      [cb setCompletes: YES];
      pass([cb completes] == YES, "setCompletes: round trips");
      [cb setButtonBordered: NO];
      pass([cb isButtonBordered] == NO, "setButtonBordered: round trips");
      [cb setItemHeight: 20.0];
      pass([cb itemHeight] == 20.0, "setItemHeight: round trips");
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

  END_SET("NSComboBox config")

  DESTROY(arp);
  return 0;
}
