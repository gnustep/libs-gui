/* NSSegmentedControl forwards the tracking mode to its cell, so an application
   can put it in NSSegmentSwitchTrackingSelectAny and select several segments at
   once (for example a bold/italic/underline style toggle).  The default is
   NSSegmentSwitchTrackingSelectOne, where selecting one segment deselects the
   others.  Checked against AppKit on a macOS runner.  The control uses the theme
   and font backend, so the set is skipped when the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSegmentedControl.h>

static NSSegmentedControl *
control(NSInteger count)
{
  NSSegmentedControl *sc = AUTORELEASE([[NSSegmentedControl alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 24)]);
  [sc setSegmentCount: count];
  return sc;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSegmentedControl *sc;

  START_SET("NSSegmentedControl multiSelect")

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
      sc = control(3);
      PASS([sc trackingMode] == NSSegmentSwitchTrackingSelectOne,
           "the default tracking mode is select-one");

      /* select-one: a second selection replaces the first */
      [sc setSelected: YES forSegment: 0];
      [sc setSelected: YES forSegment: 2];
      PASS([sc isSelectedForSegment: 0] == NO
        && [sc isSelectedForSegment: 2] == YES,
        "select-one keeps a single segment selected");
      PASS([sc selectedSegment] == 2,
        "selectedSegment is the one selected segment");

      /* select-any: several segments can be selected together */
      sc = control(3);
      [sc setTrackingMode: NSSegmentSwitchTrackingSelectAny];
      PASS([sc trackingMode] == NSSegmentSwitchTrackingSelectAny,
        "the control forwards the tracking mode to its cell");

      [sc setSelected: YES forSegment: 0];
      [sc setSelected: YES forSegment: 1];
      PASS([sc isSelectedForSegment: 0] == YES
        && [sc isSelectedForSegment: 1] == YES,
        "select-any keeps several segments selected");

      [sc setSelected: NO forSegment: 0];
      PASS([sc isSelectedForSegment: 0] == NO
        && [sc isSelectedForSegment: 1] == YES,
        "a segment can be deselected without clearing the others");
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

  END_SET("NSSegmentedControl multiSelect")

  DESTROY(arp);
  return 0;
}
