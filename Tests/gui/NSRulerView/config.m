#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSRulerView.h>

/* NSRulerView state: its orientation, origin offset, reserved thicknesses,
   flippedness and their round-trips.  These are plain properties and do not
   need a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSRulerView *r = AUTORELEASE([[NSRulerView alloc]
    initWithScrollView: nil orientation: NSHorizontalRuler]);

  /* defaults */
  PASS([r orientation] == NSHorizontalRuler,
    "the orientation is the one it was created with");
  PASS([r originOffset] == 0.0, "the origin offset starts at zero");
  PASS([r reservedThicknessForAccessoryView] == 0.0,
    "no thickness is reserved for an accessory view by default");
  PASS([r clientView] == nil, "there is no client view by default");
  PASS([r accessoryView] == nil, "there is no accessory view by default");
  PASS([r markers] == nil || [[r markers] count] == 0,
    "there are no markers by default");
  PASS([r isFlipped] == YES, "a horizontal ruler is flipped");

  /* round-trips */
  [r setRuleThickness: 20.0];
  PASS([r ruleThickness] == 20.0, "the rule thickness round-trips");
  [r setOriginOffset: 5.0];
  PASS([r originOffset] == 5.0, "the origin offset round-trips");
  [r setReservedThicknessForAccessoryView: 30.0];
  PASS([r reservedThicknessForAccessoryView] == 30.0,
    "the reserved accessory thickness round-trips");
  [r setReservedThicknessForMarkers: 12.0];
  PASS([r reservedThicknessForMarkers] == 12.0,
    "the reserved marker thickness round-trips");
  [r setOrientation: NSVerticalRuler];
  PASS([r orientation] == NSVerticalRuler, "the orientation round-trips");
  [r setMeasurementUnits: @"Centimeters"];
  PASS([[r measurementUnits] isEqualToString: @"Centimeters"],
    "the measurement units round-trip");

  /* a vertical ruler is not flipped */
  {
    NSRulerView *v = AUTORELEASE([[NSRulerView alloc]
      initWithScrollView: nil orientation: NSVerticalRuler]);
    PASS([v isFlipped] == NO, "a vertical ruler is not flipped");
  }

  DESTROY(arp);
  return 0;
}
