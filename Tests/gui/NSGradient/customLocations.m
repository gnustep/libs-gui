/* Coverage for NSGradient with custom (unevenly spaced) stop locations, which
 * basic.m does not exercise: the initWithColorsAndLocations: and
 * initWithColors:atLocations:colorSpace: initialisers, interpolation across
 * unequal segments, and clamping when the first or last stop is not at 0 or 1.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGradient.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.0001)

static NSColor *
rgb(CGFloat r, CGFloat g, CGFloat b)
{
  return [NSColor colorWithCalibratedRed: r green: g blue: b alpha: 1.0];
}

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSColor	*red = rgb(1, 0, 0);
  NSColor	*green = rgb(0, 1, 0);
  NSColor	*blue = rgb(0, 0, 1);

  START_SET("initWithColorsAndLocations records the given locations")
    NSGradient	*g = AUTORELEASE((
      [[NSGradient alloc] initWithColorsAndLocations:
      red, (CGFloat)0.0, green, (CGFloat)0.2, blue, (CGFloat)1.0, nil]));
    NSColor	*c = nil;
    CGFloat	loc = -1;

    PASS(3 == [g numberOfColorStops], "three colours give three stops");
    [g getColor: &c location: &loc atIndex: 1];
    PASS([c isEqual: green] && EQ(loc, 0.2),
      "the middle stop keeps its given colour and location");
    [g getColor: NULL location: &loc atIndex: 2];
    PASS(EQ(loc, 1.0), "the last stop keeps its given location");
  END_SET("initWithColorsAndLocations records the given locations")

  START_SET("interpolation across unequal segments")
    NSGradient	*g = AUTORELEASE((
      [[NSGradient alloc] initWithColorsAndLocations:
      red, (CGFloat)0.0, green, (CGFloat)0.2, blue, (CGFloat)1.0, nil]));
    NSColor	*c;

    /* Inside the first segment (0.0 to 0.2) the colour is a mix of red and
     * green with no blue.  The exact ratio depends on the interpolation
     * colour space, so only the mix is checked, not the proportions. */
    c = [g interpolatedColorAtLocation: 0.1];
    PASS([c redComponent] > 0.0 && [c redComponent] < 1.0
      && [c greenComponent] > 0.0 && [c greenComponent] < 1.0
      && EQ([c blueComponent], 0.0),
      "the first segment mixes red and green with no blue");

    /* Inside the second segment (0.2 to 1.0) the colour is a mix of green
     * and blue with no red. */
    c = [g interpolatedColorAtLocation: 0.6];
    PASS(EQ([c redComponent], 0.0)
      && [c greenComponent] > 0.0 && [c greenComponent] < 1.0
      && [c blueComponent] > 0.0 && [c blueComponent] < 1.0,
      "the second segment mixes green and blue with no red");

    /* A stop's own location returns that stop's colour. */
    c = [g interpolatedColorAtLocation: 0.2];
    PASS(EQ([c redComponent], 0.0) && EQ([c greenComponent], 1.0)
      && EQ([c blueComponent], 0.0),
      "the middle stop's location returns that stop's colour");
  END_SET("interpolation across unequal segments")

  START_SET("clamping when the stops do not span 0 to 1")
    NSGradient	*g = AUTORELEASE((
      [[NSGradient alloc] initWithColorsAndLocations:
      red, (CGFloat)0.25, blue, (CGFloat)0.75, nil]));
    NSColor	*c;

    /* A location below the first stop clamps to the first colour even though
     * it is above zero. */
    PASS([[g interpolatedColorAtLocation: 0.1] isEqual: red],
      "a location below the first stop clamps to the first colour");
    /* A location above the last stop clamps to the last colour even though it
     * is below one. */
    PASS([[g interpolatedColorAtLocation: 0.9] isEqual: blue],
      "a location above the last stop clamps to the last colour");
    /* Inside the interior span the colour is a mix of red and blue. */
    c = [g interpolatedColorAtLocation: 0.5];
    PASS([c redComponent] > 0.0 && [c redComponent] < 1.0
      && [c blueComponent] > 0.0 && [c blueComponent] < 1.0,
      "the interior span mixes the two stop colours");
  END_SET("clamping when the stops do not span 0 to 1")

  START_SET("initWithColors:atLocations:colorSpace: honours the locations")
    CGFloat	locations[3] = { 0.0, 0.75, 1.0 };
    NSGradient	*g = AUTORELEASE([[NSGradient alloc] initWithColors:
      ([NSArray arrayWithObjects: red, green, blue, nil])
      atLocations: locations
      colorSpace: nil]);
    CGFloat	loc = -1;
    NSColor	*c;

    PASS(3 == [g numberOfColorStops], "the colours give three stops");
    [g getColor: NULL location: &loc atIndex: 1];
    PASS(EQ(loc, 0.75), "the explicit middle location is kept");

    /* Inside the long first segment (0.0 to 0.75) the colour is a mix of the
     * first two stops (red and green) with no blue. */
    c = [g interpolatedColorAtLocation: 0.375];
    PASS([c redComponent] > 0.0 && [c redComponent] < 1.0
      && [c greenComponent] > 0.0 && [c greenComponent] < 1.0
      && EQ([c blueComponent], 0.0),
      "interpolation within the first segment follows the explicit locations");
  END_SET("initWithColors:atLocations:colorSpace: honours the locations")

  DESTROY(arp);
  return 0;
}
