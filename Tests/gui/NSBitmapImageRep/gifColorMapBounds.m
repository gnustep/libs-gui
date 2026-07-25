#import "ObjectTesting.h"
#import <Foundation/NSData.h>
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSBitmapImageRep.h>

/*
 * Regression test for two flaws in the GIF colour-map handling of
 * -_initBitmapFromGIF:.
 *
 * 1. The decoded pixel value was used to index colorMap->Colors[] without
 *    checking it against colorMap->ColorCount.  A GIF whose pixels reference
 *    an entry beyond a small palette (e.g. index 255 with a 2-colour map)
 *    read past the colour-map allocation.  The over-read is silent on a
 *    normal heap (it is proved with AddressSanitizer); this test checks that
 *    such an image now decodes without reading out of bounds.
 * 2. colorMap was taken from the per-image or global colour table and then
 *    dereferenced unconditionally; a GIF with neither table left it NULL and
 *    crashed.  This test checks that such an image is rejected.
 *
 * The GIF reader is built only when a GIF library is available, and the
 * tests below decode real GIF data, so they are compiled only when one is
 * present.  libs-gui selects the reader from the <gif_lib.h> header, so the
 * same condition is used here (config.h, which defines HAVE_LIBGIF, is not
 * installed for tests).
 */
#if defined(__has_include)
#  if __has_include(<gif_lib.h>)
#    define GS_TEST_SYSTEM_GIF 1
#  endif
#endif

static const unsigned char noColorMapGIF[] = {
  0x47,0x49,0x46,0x38,0x39,0x61,0x02,0x00,0x02,0x00,0x00,0x00,
  0x00,0x2c,0x00,0x00,0x00,0x00,0x02,0x00,0x02,0x00,0x00,0x02,
  0x03,0x04,0x80,0x02,0x00,0x3b,
};

static const unsigned char outOfRangeIndexGIF[] = {
  0x47,0x49,0x46,0x38,0x39,0x61,0x02,0x00,0x02,0x00,0x80,0x00,
  0x00,0x00,0x00,0x00,0xff,0xff,0xff,0x2c,0x00,0x00,0x00,0x00,
  0x02,0x00,0x02,0x00,0x00,0x08,0x07,0x00,0xff,0xfd,0xfb,0xf7,
  0x2f,0x20,0x00,0x3b,
};

static const unsigned char validGIF[] = {
  0x47,0x49,0x46,0x38,0x39,0x61,0x02,0x00,0x02,0x00,0x80,0x00,
  0x00,0x00,0x00,0x00,0x5a,0x8c,0xc8,0x2c,0x00,0x00,0x00,0x00,
  0x02,0x00,0x02,0x00,0x00,0x02,0x03,0x4c,0x92,0x02,0x00,0x3b,
};

int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
#if defined(GS_TEST_SYSTEM_GIF)
  NSData            *data;
  NSBitmapImageRep  *rep;
  const unsigned char *px;

  data = [NSData dataWithBytes: noColorMapGIF length: sizeof(noColorMapGIF)];
  rep = [[NSBitmapImageRep alloc] initWithData: data];
  PASS(rep == nil,
    "a GIF with no colour map is rejected, not dereferenced through NULL");
  [rep release];

  data = [NSData dataWithBytes: outOfRangeIndexGIF
                        length: sizeof(outOfRangeIndexGIF)];
  rep = [[NSBitmapImageRep alloc] initWithData: data];
  PASS(rep != nil && [rep pixelsWide] == 2 && [rep pixelsHigh] == 2,
    "a GIF with an out-of-range palette index decodes without reading past the colour map");
  [rep release];

  data = [NSData dataWithBytes: validGIF length: sizeof(validGIF)];
  rep = [[NSBitmapImageRep alloc] initWithData: data];
  px = [rep bitmapData];
  PASS(rep != nil && [rep pixelsWide] == 2 && [rep pixelsHigh] == 2
       && px != NULL && px[0] == 90 && px[1] == 140 && px[2] == 200,
    "a valid GIF still decodes correctly");
  [rep release];
#endif
  [arp release];
  return 0;
}
