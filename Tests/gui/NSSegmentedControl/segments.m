/* Coverage for NSSegmentedControl: the defaults (no segments, no selection,
   the automatic style), segment management (count, per-segment labels and
   widths), select-one tracking (setSelectedSegment: and setSelected:forSegment:
   both leave a single segment selected), per-segment enabled state and the
   segment-style round-trip.  Checked against AppKit on a macOS runner.  The
   control uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSegmentedControl.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSegmentedControl *sc;

  START_SET("NSSegmentedControl segments")

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
      sc = AUTORELEASE([[NSSegmentedControl alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 24)]);

      /* Defaults. */
      PASS([sc segmentCount] == 0, "a new control has no segments");
      PASS([sc selectedSegment] == -1, "nothing is selected by default");
      PASS([sc segmentStyle] == NSSegmentStyleAutomatic,
           "the default style is automatic");

      /* Segment management. */
      [sc setSegmentCount: 3];
      PASS([sc segmentCount] == 3, "setSegmentCount: sets the number of segments");
      [sc setLabel: @"A" forSegment: 0];
      [sc setLabel: @"B" forSegment: 1];
      [sc setLabel: @"C" forSegment: 2];
      PASS([[sc labelForSegment: 1] isEqualToString: @"B"],
           "a segment keeps its label");
      PASS([sc isEnabledForSegment: 0] == YES,
           "a segment is enabled by default");
      [sc setWidth: 40.0 forSegment: 0];
      PASS([sc widthForSegment: 0] == 40.0, "a segment keeps its width");
      PASS([sc widthForSegment: 1] == 0.0,
           "an unset width is zero (auto sized)");

      /* setSelectedSegment: selects one segment. */
      [sc setSelectedSegment: 2];
      PASS([sc selectedSegment] == 2, "setSelectedSegment: selects the segment");
      PASS([sc isSelectedForSegment: 2] == YES, "the selected segment reports selected");
      PASS([sc isSelectedForSegment: 0] == NO, "another segment is not selected");

      /* setSelected:forSegment: keeps a single selection (select-one tracking). */
      [sc setSelected: YES forSegment: 1];
      PASS([sc selectedSegment] == 1, "selecting a segment updates selectedSegment");
      PASS([sc isSelectedForSegment: 1] == YES, "the newly selected segment is selected");
      PASS([sc isSelectedForSegment: 2] == NO,
           "the previously selected segment is deselected");

      /* Per-segment enabled state. */
      [sc setEnabled: NO forSegment: 1];
      PASS([sc isEnabledForSegment: 1] == NO, "a segment can be disabled");
      PASS([sc isEnabledForSegment: 0] == YES,
           "disabling one segment leaves the others enabled");

      /* Segment style round-trip. */
      [sc setSegmentStyle: NSSegmentStyleCapsule];
      PASS([sc segmentStyle] == NSSegmentStyleCapsule,
           "setSegmentStyle: round trips");
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

  END_SET("NSSegmentedControl segments")

  DESTROY(arp);
  return 0;
}
