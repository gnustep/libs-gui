/* Coverage for the NSSlider convenience constructors: sliderWithTarget:action:
   makes a slider over the default zero-to-one range wired to the action, and
   sliderWithValue:minValue:maxValue:target:action: sets the given range and
   value.  Checked against AppKit on a macOS runner.  Building the slider
   touches the font/graphics backend, so the set is skipped when the backend is
   unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSlider.h>

@interface SliderTarget : NSObject
- (void) moved: (id)sender;
@end
@implementation SliderTarget
- (void) moved: (id)sender { }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  SliderTarget *t;

  START_SET("NSSlider convenience constructors")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSlider *s;
      SEL a = @selector(moved:);

      t = AUTORELEASE([[SliderTarget alloc] init]);

      s = [NSSlider sliderWithTarget: t action: a];
      PASS(s != nil && [s minValue] == 0.0 && [s maxValue] == 1.0
        && [s doubleValue] == 0.0 && [s target] == t && sel_isEqual([s action], a),
        "sliderWithTarget:action: makes a zero-to-one slider wired to the action");

      s = [NSSlider sliderWithValue: 5.0 minValue: 2.0 maxValue: 9.0
                             target: t action: a];
      PASS(s != nil && [s minValue] == 2.0 && [s maxValue] == 9.0
        && [s doubleValue] == 5.0 && [s target] == t && sel_isEqual([s action], a),
        "sliderWithValue:minValue:maxValue:target:action: sets the range and value");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSlider convenience constructors")

  DESTROY(arp);
  return 0;
}
