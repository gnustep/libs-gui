/* -[NSBitmapImageRep colorAtX:y:] on a pixel whose alpha is zero.
 *
 * The colour components of a premultiplied bitmap are divided by the alpha to
 * undo the premultiplication, so an alpha of zero divides by zero and gives
 * infinity or a NaN rather than a colour.  A NaN fails every comparison, so a
 * caller checking a component sees neither the value it expects nor the
 * opposite of it.  AppKit answers the raw components scaled, exactly as it
 * does for a bitmap that is not premultiplied.
 *
 * None of this needs a backend, so it runs anywhere.
 */
#import <Foundation/NSObject.h>
#import "Testing.h"

#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>

#include <math.h>

static BOOL
nearly(CGFloat a, CGFloat b)
{
  if (isnan((double)a) || isinf((double)a))
    {
      return NO;
    }
  return (a - b < 0.01 && b - a < 0.01) ? YES : NO;
}

/* A one pixel bitmap of the given colour space and format, holding `count`
   samples taken from `s`. */
static NSBitmapImageRep *
repWith(NSString *space, NSBitmapFormat format, int spp,
        NSUInteger s0, NSUInteger s1, NSUInteger s2, NSUInteger s3)
{
  NSBitmapImageRep *rep;
  NSUInteger px[5];

  rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL pixelsWide: 1 pixelsHigh: 1
                bitsPerSample: 8 samplesPerPixel: spp hasAlpha: YES
                     isPlanar: NO colorSpaceName: space
                 bitmapFormat: format bytesPerRow: spp bitsPerPixel: spp * 8]);
  px[0] = s0; px[1] = s1; px[2] = s2; px[3] = s3; px[4] = 0;
  [rep setPixel: px atX: 0 y: 0];
  return rep;
}

int
main(int argc, char **argv)
{
  START_SET("colour at a zero alpha pixel")

  NSBitmapImageRep	*rep;
  NSColor		*c;

  /* Premultiplied, alpha last.  A red left in the buffer with an alpha of
     zero is what an offscreen drawable can hold. */
  rep = repWith(NSDeviceRGBColorSpace, 0, 4, 255, 0, 0, 0);
  c = [rep colorAtX: 0 y: 0];
  PASS(c != nil, "a zero alpha pixel still gives a colour");
  PASS(c != nil && !isnan((double)[c redComponent])
       && !isnan((double)[c greenComponent])
       && !isnan((double)[c blueComponent]),
    "no component of a zero alpha pixel is a NaN");
  PASS(c != nil && nearly([c redComponent], 1.0)
       && nearly([c greenComponent], 0.0)
       && nearly([c blueComponent], 0.0)
       && nearly([c alphaComponent], 0.0),
    "a zero alpha pixel keeps its stored components");

  rep = repWith(NSDeviceRGBColorSpace, 0, 4, 0, 0, 0, 0);
  c = [rep colorAtX: 0 y: 0];
  PASS(c != nil && nearly([c redComponent], 0.0)
       && nearly([c greenComponent], 0.0)
       && nearly([c blueComponent], 0.0)
       && nearly([c alphaComponent], 0.0),
    "an entirely zero pixel is black and clear");

  /* The premultiplication is still undone when there is an alpha to divide
     by: half transparent red is stored halved and reads back full. */
  rep = repWith(NSDeviceRGBColorSpace, 0, 4, 128, 0, 0, 128);
  c = [rep colorAtX: 0 y: 0];
  PASS(c != nil && nearly([c redComponent], 1.0)
       && nearly([c alphaComponent], 0.502),
    "a half transparent pixel still has its premultiplication undone");

  rep = repWith(NSDeviceRGBColorSpace, 0, 4, 255, 0, 0, 255);
  c = [rep colorAtX: 0 y: 0];
  PASS(c != nil && nearly([c redComponent], 1.0)
       && nearly([c alphaComponent], 1.0),
    "an opaque pixel is unaffected");

  /* A bitmap that is not premultiplied never divided, and is unchanged. */
  rep = repWith(NSDeviceRGBColorSpace, NSAlphaNonpremultipliedBitmapFormat,
                4, 255, 0, 0, 0);
  c = [rep colorAtX: 0 y: 0];
  PASS(c != nil && nearly([c redComponent], 1.0)
       && nearly([c alphaComponent], 0.0),
    "a zero alpha pixel that is not premultiplied keeps its components");

  /* The alpha is read from the front when the format says so. */
  rep = repWith(NSDeviceRGBColorSpace, NSAlphaFirstBitmapFormat,
                4, 0, 255, 0, 0);
  c = [rep colorAtX: 0 y: 0];
  PASS(c != nil && nearly([c redComponent], 1.0)
       && nearly([c greenComponent], 0.0)
       && nearly([c alphaComponent], 0.0),
    "a zero alpha pixel with the alpha first keeps its components");

  /* The white colour space divides in the same way. */
  rep = repWith(NSDeviceWhiteColorSpace, 0, 2, 255, 0, 0, 0);
  c = [rep colorAtX: 0 y: 0];
  PASS(c != nil && !isnan((double)[c whiteComponent])
       && nearly([c whiteComponent], 1.0)
       && nearly([c alphaComponent], 0.0),
    "a zero alpha white pixel keeps its stored component");

  rep = repWith(NSDeviceWhiteColorSpace, 0, 2, 0, 0, 0, 0);
  c = [rep colorAtX: 0 y: 0];
  PASS(c != nil && nearly([c whiteComponent], 0.0)
       && nearly([c alphaComponent], 0.0),
    "an entirely zero white pixel is black and clear");

  END_SET("colour at a zero alpha pixel")

  return 0;
}
