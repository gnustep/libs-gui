/* Coverage for NSColorSpace: the model enum values, and the colour space
 * model, component count, name and singleton identity of the standard colour
 * spaces.  These are plain value objects and need no backend.
 *
 * The generic spaces on macOS carry an ICC profile and longer localized
 * names; this class does not, so the ICC data and the exact name are not
 * covered.
 */
#include "Testing.h"
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSString.h>
#include <AppKit/NSColorSpace.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("model enum values")
    PASS(NSUnknownColorSpaceModel == -1 && NSGrayColorSpaceModel == 0
      && NSRGBColorSpaceModel == 1 && NSCMYKColorSpaceModel == 2
      && NSLABColorSpaceModel == 3 && NSDeviceNColorSpaceModel == 4,
      "the NSColorSpaceModel values match AppKit");
  END_SET("model enum values")

  START_SET("generic colour spaces")
    NSColorSpace	*rgb = [NSColorSpace genericRGBColorSpace];
    NSColorSpace	*gray = [NSColorSpace genericGrayColorSpace];
    NSColorSpace	*cmyk = [NSColorSpace genericCMYKColorSpace];

    PASS([rgb colorSpaceModel] == NSRGBColorSpaceModel
      && [rgb numberOfColorComponents] == 3,
      "the generic RGB space is an RGB model with three components");
    PASS([gray colorSpaceModel] == NSGrayColorSpaceModel
      && [gray numberOfColorComponents] == 1,
      "the generic gray space is a gray model with one component");
    PASS([cmyk colorSpaceModel] == NSCMYKColorSpaceModel
      && [cmyk numberOfColorComponents] == 4,
      "the generic CMYK space is a CMYK model with four components");
    PASS([rgb localizedName] != nil, "a colour space has a localized name");
  END_SET("generic colour spaces")

  START_SET("device colour spaces")
    NSColorSpace	*rgb = [NSColorSpace deviceRGBColorSpace];
    NSColorSpace	*gray = [NSColorSpace deviceGrayColorSpace];
    NSColorSpace	*cmyk = [NSColorSpace deviceCMYKColorSpace];

    PASS([rgb colorSpaceModel] == NSRGBColorSpaceModel
      && [rgb numberOfColorComponents] == 3,
      "the device RGB space is an RGB model with three components");
    PASS([gray colorSpaceModel] == NSGrayColorSpaceModel
      && [gray numberOfColorComponents] == 1,
      "the device gray space is a gray model with one component");
    PASS([cmyk colorSpaceModel] == NSCMYKColorSpaceModel
      && [cmyk numberOfColorComponents] == 4,
      "the device CMYK space is a CMYK model with four components");
  END_SET("device colour spaces")

  START_SET("generic RGB has an ICC profile")
    NSData	*icc = [[NSColorSpace genericRGBColorSpace] ICCProfileData];

    PASS(icc != nil, "the generic RGB space reports ICC profile data");
    if (icc != nil && [icc length] >= 40)
      {
        const unsigned char *b = [icc bytes];

        PASS(b[36] == 'a' && b[37] == 'c' && b[38] == 's' && b[39] == 'p',
          "the profile carries the acsp signature");
      }
    else
      {
        PASS(0, "the profile is long enough to hold a header");
      }
  END_SET("generic RGB has an ICC profile")

  START_SET("standard spaces are shared")
    PASS([NSColorSpace genericRGBColorSpace]
      == [NSColorSpace genericRGBColorSpace],
      "the generic RGB space is the same object each time");
    PASS([NSColorSpace deviceRGBColorSpace]
      == [NSColorSpace deviceRGBColorSpace],
      "the device RGB space is the same object each time");
    PASS([NSColorSpace genericRGBColorSpace]
      != [NSColorSpace deviceRGBColorSpace],
      "the generic and device RGB spaces are different objects");
  END_SET("standard spaces are shared")

  DESTROY(arp);
  return 0;
}
