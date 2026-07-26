/* Coverage for NSSegmentedCell select-any tracking: in the SelectAny mode a
   segment stays selected when another is selected, selectedSegment reports the
   most recently selected one, deselecting a segment leaves the others alone,
   and a disabled segment cannot be selected.  model.m already covers the
   default SelectOne tracking; this covers the multiple-selection mode.  The
   cell touches the font backend, so the set is skipped when the backend is
   unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSegmentedCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSegmentedCell *cell;

  START_SET("NSSegmentedCell selectAny")

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

  cell = AUTORELEASE([[NSSegmentedCell alloc] init]);
  [cell setSegmentCount: 3];
  [cell setTrackingMode: NSSegmentSwitchTrackingSelectAny];
  PASS([cell trackingMode] == NSSegmentSwitchTrackingSelectAny,
    "the tracking mode round trips to SelectAny");

  /* Selecting a second segment leaves the first selected. */
  [cell setSelected: YES forSegment: 0];
  [cell setSelected: YES forSegment: 1];
  PASS([cell isSelectedForSegment: 0] == YES
    && [cell isSelectedForSegment: 1] == YES,
    "SelectAny keeps both segments selected");
  PASS([cell selectedSegment] == 1,
    "selectedSegment reports the most recently selected segment");

  /* Deselecting one segment leaves the other selected. */
  [cell setSelected: NO forSegment: 0];
  PASS([cell isSelectedForSegment: 0] == NO
    && [cell isSelectedForSegment: 1] == YES,
    "deselecting one segment leaves the other selected");

  /* A disabled segment cannot be selected. */
  [cell setEnabled: NO forSegment: 2];
  [cell setSelected: YES forSegment: 2];
  PASS([cell isSelectedForSegment: 2] == NO,
    "a disabled segment cannot be selected");

  END_SET("NSSegmentedCell selectAny")

  DESTROY(arp);
  return 0;
}
