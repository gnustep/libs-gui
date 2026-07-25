/* Coverage for the NSSegmentedControl convenience constructors: the labelled
   and image variants build one segment per element, carry the tracking mode,
   and wire up the target and action.  Checked against AppKit on a macOS runner.
   Building the control touches the font/graphics backend, so the set is skipped
   when the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSegmentedControl.h>
#include <AppKit/NSSegmentedCell.h>
#include <AppKit/NSImage.h>

@interface SegTarget : NSObject
- (void) picked: (id)sender;
@end
@implementation SegTarget
- (void) picked: (id)sender { }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  SegTarget *t;

  START_SET("NSSegmentedControl convenience constructors")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSegmentedControl *sc;
      NSImage *image;
      SEL a = @selector(picked:);

      t = AUTORELEASE([[SegTarget alloc] init]);

      sc = [NSSegmentedControl
        segmentedControlWithLabels:
          [NSArray arrayWithObjects: @"One", @"Two", @"Three", nil]
        trackingMode: NSSegmentSwitchTrackingSelectOne
        target: t action: a];
      PASS(sc != nil && [sc segmentCount] == 3
        && [[sc labelForSegment: 0] isEqual: @"One"]
        && [[sc labelForSegment: 2] isEqual: @"Three"]
        && [(NSSegmentedCell *)[sc cell] trackingMode]
             == NSSegmentSwitchTrackingSelectOne
        && [sc target] == t && sel_isEqual([sc action], a),
        "segmentedControlWithLabels:... builds one labelled segment per element");

      image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
      sc = [NSSegmentedControl
        segmentedControlWithImages:
          [NSArray arrayWithObjects: image, image, nil]
        trackingMode: NSSegmentSwitchTrackingSelectAny
        target: t action: a];
      PASS(sc != nil && [sc segmentCount] == 2
        && [sc imageForSegment: 0] == image
        && [(NSSegmentedCell *)[sc cell] trackingMode]
             == NSSegmentSwitchTrackingSelectAny
        && [sc target] == t && sel_isEqual([sc action], a),
        "segmentedControlWithImages:... builds one image segment per element");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSegmentedControl convenience constructors")

  DESTROY(arp);
  return 0;
}
