/* Coverage for the NSSegmentedCell model: the defaults, the segment count,
   the per-segment label, width, enabled, tag and tool tip accessors, the
   single-selection tracking (selecting a segment moves the selection), the
   selection by tag, and the segment style.  The cell touches the font
   backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <math.h>
#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSegmentedCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSegmentedCell *cell;

  START_SET("NSSegmentedCell model")

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

  /* Defaults. */
  pass([cell segmentCount] == 0, "a new cell has no segments");
  pass([cell selectedSegment] == -1, "a new cell has no selection");
  pass([cell trackingMode] == NSSegmentSwitchTrackingSelectOne,
       "the default tracking mode selects one segment");

  /* Segment count and per-segment defaults. */
  [cell setSegmentCount: 3];
  pass([cell segmentCount] == 3, "setSegmentCount: sets the number of segments");
  pass([cell labelForSegment: 0] == nil, "a new segment has no label");
  pass([cell widthForSegment: 0] == 0.0, "a new segment has zero width");
  pass([cell isEnabledForSegment: 0] == YES, "a new segment is enabled");
  pass([cell tagForSegment: 0] == 0, "a new segment has a zero tag");
  pass([cell isSelectedForSegment: 0] == NO, "a new segment is not selected");

  /* Per-segment accessors round-trip. */
  [cell setLabel: @"One" forSegment: 0];
  [cell setLabel: @"Two" forSegment: 1];
  [cell setLabel: @"Three" forSegment: 2];
  [cell setWidth: 40.0 forSegment: 1];
  [cell setTag: 77 forSegment: 2];
  [cell setToolTip: @"tip" forSegment: 0];
  pass([[cell labelForSegment: 1] isEqualToString: @"Two"], "the label round trips");
  pass([cell widthForSegment: 1] == 40.0, "the width round trips");
  pass([cell tagForSegment: 2] == 77, "the tag round trips");
  pass([[cell toolTipForSegment: 0] isEqualToString: @"tip"], "the tool tip round trips");

  /* Single-selection tracking: selecting a segment moves the selection. */
  [cell setSelectedSegment: 1];
  pass([cell selectedSegment] == 1 && [cell isSelectedForSegment: 1] == YES,
    "setSelectedSegment: selects the segment");
  [cell setSelectedSegment: 2];
  pass([cell selectedSegment] == 2 && [cell isSelectedForSegment: 2] == YES
    && [cell isSelectedForSegment: 1] == NO,
    "selecting another segment deselects the previous one");
  [cell setSelected: NO forSegment: 2];
  pass([cell isSelectedForSegment: 2] == NO, "setSelected: NO deselects the segment");

  /* Selection by tag. */
  [cell selectSegmentWithTag: 77];
  pass([cell selectedSegment] == 2, "selectSegmentWithTag: selects the tagged segment");

  /* Shrinking keeps the remaining segments. */
  [cell setSegmentCount: 2];
  pass([cell segmentCount] == 2 && [[cell labelForSegment: 1] isEqualToString: @"Two"],
    "shrinking the count keeps the remaining segments");

  /* Segment style. */
  [cell setSegmentStyle: NSSegmentStyleRounded];
  pass([cell segmentStyle] == NSSegmentStyleRounded, "setSegmentStyle: round trips");

  END_SET("NSSegmentedCell model")

  DESTROY(arp);
  return 0;
}
