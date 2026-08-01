/* A pattern colour has no components to convert, so asking it for a component
 * based colour space answers nil rather than raising: a caller is expected to
 * test the result, which is what AppKit does.  Asking for a component itself
 * does raise, because there is no value to give.  These are plain value
 * operations with no window server, so the test runs headlessly.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSGraphics.h>

int
main(int argc, char **argv)
{
  START_SET("NSColor patternColour")

  NSImage *image = AUTORELEASE([[NSImage alloc]
    initWithSize: NSMakeSize(4, 4)]);
  NSColor *pattern = [NSColor colorWithPatternImage: image];

  PASS(pattern != nil, "a pattern colour is made from an image");
  PASS_EQUAL([pattern colorSpaceName], NSPatternColorSpace,
    "a pattern colour is in the pattern colour space");
  PASS([pattern patternImage] == image,
    "a pattern colour keeps the image it was made from");

  /* The conversions.  Nil, not an exception. */
  PASS([pattern colorUsingColorSpaceName: NSCalibratedRGBColorSpace] == nil,
    "a pattern colour does not convert to the calibrated RGB space");
  PASS([pattern colorUsingColorSpaceName: NSDeviceRGBColorSpace] == nil,
    "a pattern colour does not convert to the device RGB space");
  PASS([pattern colorUsingColorSpaceName: NSDeviceWhiteColorSpace] == nil,
    "a pattern colour does not convert to the device white space");
  PASS([pattern colorUsingColorSpaceName: NSDeviceCMYKColorSpace] == nil,
    "a pattern colour does not convert to the device CMYK space");

  /* Its own space is not a conversion at all. */
  PASS([pattern colorUsingColorSpaceName: NSPatternColorSpace] == pattern,
    "a pattern colour asked for its own colour space answers itself");

  /* A component has no value to give, so that one does raise. */
  {
    BOOL raised = NO;

    NS_DURING
      (void)[pattern redComponent];
    NS_HANDLER
      raised = YES;
    NS_ENDHANDLER
    PASS(raised, "asking a pattern colour for a component raises");
  }

  END_SET("NSColor patternColour")

  return 0;
}
