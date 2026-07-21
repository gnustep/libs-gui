/* Coverage for NSGradient: construction, colour stops and the location
 * interpolation (interpolatedColorAtLocation:).
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

  START_SET("construction and colour stops")
    NSGradient	*g = [[NSGradient alloc] initWithStartingColor: red
						   endingColor: blue];
    NSColor	*c = nil;
    CGFloat	loc = -1;

    PASS(g != nil, "a two-colour gradient is created");
    PASS(2 == [g numberOfColorStops], "it has two colour stops");
    PASS([g colorSpace] != nil, "it reports a colour space");

    [g getColor: &c location: &loc atIndex: 0];
    PASS([c isEqual: red] && EQ(loc, 0.0),
      "the first stop is the starting colour at location 0");
    [g getColor: &c location: &loc atIndex: 1];
    PASS([c isEqual: blue] && EQ(loc, 1.0),
      "the last stop is the ending colour at location 1");
  END_SET("construction and colour stops")

  START_SET("initWithColors evenly spaces the stops")
    NSGradient	*g = [[NSGradient alloc] initWithColors:
      [NSArray arrayWithObjects: red, green, blue, nil]];
    CGFloat	loc = -1;

    PASS(3 == [g numberOfColorStops], "three colours give three stops");
    [g getColor: NULL location: &loc atIndex: 0];
    PASS(EQ(loc, 0.0), "first of three stops is at 0");
    [g getColor: NULL location: &loc atIndex: 1];
    PASS(EQ(loc, 0.5), "middle of three stops is at 0.5");
    [g getColor: NULL location: &loc atIndex: 2];
    PASS(EQ(loc, 1.0), "last of three stops is at 1");
  END_SET("initWithColors evenly spaces the stops")

  START_SET("interpolatedColorAtLocation endpoints")
    NSGradient	*g = [[NSGradient alloc] initWithStartingColor: red
						   endingColor: blue];

    PASS([[g interpolatedColorAtLocation: 0.0] isEqual: red],
      "location 0 is the starting colour");
    PASS([[g interpolatedColorAtLocation: 1.0] isEqual: blue],
      "location 1 is the ending colour");
    PASS([[g interpolatedColorAtLocation: -1.0] isEqual: red],
      "a location below the range clamps to the starting colour");
    PASS([[g interpolatedColorAtLocation: 2.0] isEqual: blue],
      "a location above the range clamps to the ending colour");
  END_SET("interpolatedColorAtLocation endpoints")

  START_SET("interpolatedColorAtLocation interpolates toward the nearer stop")
    NSGradient	*g = [[NSGradient alloc] initWithStartingColor: red
						   endingColor: blue];
    NSColor	*c;

    c = [g interpolatedColorAtLocation: 0.25];
    PASS(EQ([c redComponent], 0.75) && EQ([c blueComponent], 0.25),
      "a quarter of the way is three-quarters the starting colour");

    c = [g interpolatedColorAtLocation: 0.5];
    PASS(EQ([c redComponent], 0.5) && EQ([c blueComponent], 0.5),
      "the middle is an even mix");

    c = [g interpolatedColorAtLocation: 0.75];
    PASS(EQ([c redComponent], 0.25) && EQ([c blueComponent], 0.75),
      "three-quarters of the way is three-quarters the ending colour");
  END_SET("interpolatedColorAtLocation interpolates toward the nearer stop")

  START_SET("interpolatedColorAtLocation across three stops")
    NSGradient	*g = [[NSGradient alloc] initWithColors:
      [NSArray arrayWithObjects: red, green, blue, nil]];
    NSColor	*c;

    c = [g interpolatedColorAtLocation: 0.5];
    PASS(EQ([c redComponent], 0.0) && EQ([c greenComponent], 1.0)
      && EQ([c blueComponent], 0.0),
      "the middle stop's own location returns that stop's colour");

    c = [g interpolatedColorAtLocation: 0.25];
    PASS(EQ([c redComponent], 0.5) && EQ([c greenComponent], 0.5)
      && EQ([c blueComponent], 0.0),
      "a quarter of the way is halfway between the first two stops");
  END_SET("interpolatedColorAtLocation across three stops")

  START_SET("copy")
    NSGradient	*g = [[NSGradient alloc] initWithStartingColor: red
						   endingColor: blue];
    NSGradient	*c = [g copy];

    PASS(c != nil && c != g, "copy is a distinct object");
    PASS(2 == [c numberOfColorStops], "copy preserves the stop count");
    PASS([[c interpolatedColorAtLocation: 0.25] redComponent] > 0.7,
      "copy interpolates like the original");
  END_SET("copy")

  DESTROY(arp);
  return 0;
}
