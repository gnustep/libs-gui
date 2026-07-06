/* Coverage for NSColor: component accessors, clamping, the RGB/HSB and
 * CMYK/RGB conversions, alpha handling, blending and colour-space conversion.
 */
#include "Testing.h"
#include <math.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSColorSpace.h>
#include <AppKit/NSGraphics.h>

#define EQ(a, b) (fabs((double)(a) - (double)(b)) < 0.0001)

int main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("calibrated RGB components")
    NSColor *c = [NSColor colorWithCalibratedRed: 0.2 green: 0.4
					    blue: 0.6 alpha: 0.8];

    PASS(EQ([c redComponent], 0.2), "red component reads back");
    PASS(EQ([c greenComponent], 0.4), "green component reads back");
    PASS(EQ([c blueComponent], 0.6), "blue component reads back");
    PASS(EQ([c alphaComponent], 0.8), "alpha component reads back");
    PASS([[c colorSpaceName] isEqualToString: NSCalibratedRGBColorSpace],
      "colorSpaceName is the calibrated RGB space");
    PASS(4 == [c numberOfComponents],
      "an RGB colour reports four components");
  END_SET("calibrated RGB components")

  START_SET("device RGB clamps its components")
    NSColor *c = [NSColor colorWithDeviceRed: 1.5 green: -0.5
					blue: 0.5 alpha: 2.0];

    PASS(EQ([c redComponent], 1.0), "red above 1 clamps to 1");
    PASS(EQ([c greenComponent], 0.0), "green below 0 clamps to 0");
    PASS(EQ([c blueComponent], 0.5), "an in-range component is unchanged");
    PASS(EQ([c alphaComponent], 1.0), "alpha above 1 clamps to 1");
    PASS([[c colorSpaceName] isEqualToString: NSDeviceRGBColorSpace],
      "colorSpaceName is the device RGB space");
  END_SET("device RGB clamps its components")

  START_SET("RGB to HSB")
    CGFloat	h, s, b, a;

    [[NSColor colorWithCalibratedRed: 1 green: 0 blue: 0 alpha: 1]
      getHue: &h saturation: &s brightness: &b alpha: &a];
    PASS(EQ(h, 0.0) && EQ(s, 1.0) && EQ(b, 1.0),
      "pure red is hue 0, saturation 1, brightness 1");

    [[NSColor colorWithCalibratedRed: 0 green: 1 blue: 0 alpha: 1]
      getHue: &h saturation: &s brightness: &b alpha: &a];
    PASS(EQ(h, 1.0 / 3.0) && EQ(s, 1.0) && EQ(b, 1.0),
      "pure green is hue 1/3");

    [[NSColor colorWithCalibratedRed: 0 green: 0 blue: 1 alpha: 1]
      getHue: &h saturation: &s brightness: &b alpha: &a];
    PASS(EQ(h, 2.0 / 3.0) && EQ(s, 1.0) && EQ(b, 1.0),
      "pure blue is hue 2/3");

    [[NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1]
      getHue: &h saturation: &s brightness: &b alpha: &a];
    PASS(EQ(s, 0.0) && EQ(b, 0.5),
      "a gray has zero saturation and brightness of its level");
  END_SET("RGB to HSB")

  START_SET("HSB to RGB")
    NSColor *c;

    c = [NSColor colorWithCalibratedHue: 0.0 saturation: 1.0
			     brightness: 1.0 alpha: 1.0];
    PASS(EQ([c redComponent], 1.0) && EQ([c greenComponent], 0.0)
      && EQ([c blueComponent], 0.0), "hue 0 is red");

    c = [NSColor colorWithCalibratedHue: 1.0 / 3.0 saturation: 1.0
			     brightness: 1.0 alpha: 1.0];
    PASS(EQ([c redComponent], 0.0) && EQ([c greenComponent], 1.0)
      && EQ([c blueComponent], 0.0), "hue 1/3 is green");

    c = [NSColor colorWithCalibratedHue: 2.0 / 3.0 saturation: 1.0
			     brightness: 1.0 alpha: 1.0];
    PASS(EQ([c redComponent], 0.0) && EQ([c greenComponent], 0.0)
      && EQ([c blueComponent], 1.0), "hue 2/3 is blue");
  END_SET("HSB to RGB")

  START_SET("RGB/HSB round-trips")
    CGFloat	t[][3] = {
      {0.2, 0.5, 0.8}, {0.9, 0.3, 0.6}, {0.1, 0.7, 0.4}, {0.5, 0.5, 0.5}
    };
    int		i;
    BOOL	ok = YES;

    for (i = 0; i < 4; i++)
      {
	CGFloat	h, s, b, a;
	NSColor	*rgb = [NSColor colorWithCalibratedRed: t[i][0]
	  green: t[i][1] blue: t[i][2] alpha: 1.0];
	NSColor	*back;

	[rgb getHue: &h saturation: &s brightness: &b alpha: &a];
	back = [NSColor colorWithCalibratedHue: h saturation: s
	  brightness: b alpha: a];
	if (!EQ([back redComponent], t[i][0])
	  || !EQ([back greenComponent], t[i][1])
	  || !EQ([back blueComponent], t[i][2]))
	  {
	    ok = NO;
	  }
      }
    PASS(ok == YES, "RGB -> HSB -> RGB reproduces the original colour");
  END_SET("RGB/HSB round-trips")

  START_SET("colorWithAlphaComponent")
    NSColor *c = [NSColor colorWithCalibratedRed: 0.3 green: 0.3
					    blue: 0.3 alpha: 1.0];
    NSColor *faded = [c colorWithAlphaComponent: 0.25];

    PASS(EQ([faded alphaComponent], 0.25), "alpha is replaced");
    PASS(EQ([faded redComponent], 0.3), "the colour is otherwise unchanged");
    PASS(EQ([[c colorWithAlphaComponent: 5.0] alphaComponent], 1.0),
      "an alpha above 1 clamps to 1");
  END_SET("colorWithAlphaComponent")

  START_SET("blendedColorWithFraction")
    NSColor *black = [NSColor colorWithCalibratedRed: 0 green: 0
						blue: 0 alpha: 1];
    NSColor *white = [NSColor colorWithCalibratedRed: 1 green: 1
						blue: 1 alpha: 1];
    NSColor *mid = [black blendedColorWithFraction: 0.5 ofColor: white];

    PASS(EQ([mid redComponent], 0.5) && EQ([mid greenComponent], 0.5)
      && EQ([mid blueComponent], 0.5), "an even blend is the midpoint");

    PASS([black blendedColorWithFraction: 0.0 ofColor: white] == black,
      "a fraction of 0 returns the receiver");
    PASS([black blendedColorWithFraction: 1.0 ofColor: white] == white,
      "a fraction of 1 returns the other colour");
  END_SET("blendedColorWithFraction")

  START_SET("colorUsingColorSpaceName")
    NSColor	*cal = [NSColor colorWithCalibratedRed: 0.25 green: 0.5
					     blue: 0.75 alpha: 1.0];
    NSColor	*dev = [cal colorUsingColorSpaceName: NSDeviceRGBColorSpace];

    PASS(dev != nil
      && [[dev colorSpaceName] isEqualToString: NSDeviceRGBColorSpace],
      "calibrated RGB converts to device RGB");
    PASS(EQ([dev redComponent], 0.25) && EQ([dev greenComponent], 0.5)
      && EQ([dev blueComponent], 0.75),
      "the components survive the RGB space change");
    PASS([cal colorUsingColorSpaceName: NSCalibratedRGBColorSpace] == cal,
      "converting to the current space returns the receiver");
  END_SET("colorUsingColorSpaceName")

  START_SET("device CMYK")
    NSColor	*k = [NSColor colorWithDeviceCyan: 0.1 magenta: 0.2
				    yellow: 0.3 black: 0.4 alpha: 1.0];
    NSColor	*cyan = [NSColor colorWithDeviceCyan: 1 magenta: 0
				       yellow: 0 black: 0 alpha: 1];
    NSColor	*black = [NSColor colorWithDeviceCyan: 0 magenta: 0
					yellow: 0 black: 1 alpha: 1];
    NSColor	*rgb;

    PASS(EQ([k cyanComponent], 0.1) && EQ([k magentaComponent], 0.2)
      && EQ([k yellowComponent], 0.3) && EQ([k blackComponent], 0.4),
      "CMYK components read back");

    rgb = [cyan colorUsingColorSpaceName: NSDeviceRGBColorSpace];
    PASS(EQ([rgb redComponent], 0.0) && EQ([rgb greenComponent], 1.0)
      && EQ([rgb blueComponent], 1.0), "pure cyan converts to (0,1,1) RGB");

    rgb = [black colorUsingColorSpaceName: NSDeviceRGBColorSpace];
    PASS(EQ([rgb redComponent], 0.0) && EQ([rgb greenComponent], 0.0)
      && EQ([rgb blueComponent], 0.0), "full black converts to (0,0,0) RGB");
  END_SET("device CMYK")

  START_SET("white colour")
    NSColor	*w = [NSColor colorWithCalibratedWhite: 0.6 alpha: 1.0];

    PASS(EQ([w whiteComponent], 0.6), "white component reads back");
    PASS([[w colorSpaceName] isEqualToString: NSCalibratedWhiteColorSpace],
      "colorSpaceName is the calibrated white space");
  END_SET("white colour")

  START_SET("equality")
    NSColor	*a = [NSColor colorWithCalibratedRed: 0.3 green: 0.6
					    blue: 0.9 alpha: 1.0];
    NSColor	*b = [NSColor colorWithCalibratedRed: 0.3 green: 0.6
					    blue: 0.9 alpha: 1.0];
    NSColor	*d = [NSColor colorWithCalibratedRed: 0.3 green: 0.6
					    blue: 0.9 alpha: 0.5];

    PASS([a isEqual: b], "two identical colours are equal");
    PASS(![a isEqual: d], "colours differing only in alpha are not equal");
  END_SET("equality")

  DESTROY(arp);
  return 0;
}
