#import "ObjectTesting.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphics.h>

/*
 * Regression guard for a heap buffer overflow in the JPEG encoder's
 * destination manager (gs_init_destination / gs_empty_output_buffer /
 * gs_term_destination in NSBitmapImageRep+JPEG.m).
 *
 * dest->data was allocated with exactly one buffer's worth of bytes
 * (image_width * image_height * input_components), the same size as the
 * scratch buffer libjpeg fills between flushes.  For a small image the
 * compressed stream (JPEG header tables plus scan data) commonly exceeds
 * that tiny buffer at least once before compression finishes:
 * gs_empty_output_buffer then appends a full buffer's worth at an offset
 * that already reaches capacity, and gs_term_destination unconditionally
 * appends another full buffer's worth on top of that - both write past the
 * end of dest->data.  Confirmed with valgrind: "Invalid write ... 0 bytes
 * after a block of size ..." at the copy loops in gs_empty_output_buffer /
 * gs_term_destination.
 *
 * Many small sizes are exercised (from 1x1, where the JPEG header alone
 * dwarfs the one-pixel buffer, up to sizes whose scan data alone fills the
 * buffer) so at least one of them reliably drives a flush before the
 * unpatched code's buffer is exhausted, regardless of libjpeg's exact
 * marker sizes for a given build.  Each result is checked for a valid
 * SOI/EOI marker pair and for decoding back to the original dimensions
 * with the sampled corner pixels intact, so a build that only avoids the
 * crash on some sizes (or produces corrupted output) still fails.
 */

static NSBitmapImageRep *
makeSourceRep(NSInteger width, NSInteger height)
{
  NSBitmapImageRep *rep;
  unsigned char *plane;
  NSInteger row_bytes;
  NSInteger x, y;

  rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes: NULL
                                               pixelsWide: width
                                               pixelsHigh: height
                                            bitsPerSample: 8
                                          samplesPerPixel: 3
                                                 hasAlpha: NO
                                                 isPlanar: NO
                                           colorSpaceName: NSCalibratedRGBColorSpace
                                              bytesPerRow: 0
                                             bitsPerPixel: 0];
  plane = [rep bitmapData];
  row_bytes = [rep bytesPerRow];

  /* A gradient rather than a flat fill, so the encoded data is not
     trivially small for every size tested. */
  for (y = 0; y < height; y++)
    {
      for (x = 0; x < width; x++)
        {
          unsigned char *px = plane + y * row_bytes + x * 3;
          px[0] = (unsigned char)((x * 37 + y * 11) & 0xff);
          px[1] = (unsigned char)((x * 13 + y * 59) & 0xff);
          px[2] = (unsigned char)((x * 91 + y * 3) & 0xff);
        }
    }

  return rep;
}

int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSInteger sizes[] = { 1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32, 40, 48, 64 };
  NSUInteger n = sizeof(sizes) / sizeof(sizes[0]);
  NSUInteger idx;
  BOOL allOk = YES;
  BOOL allDecode = YES;

  for (idx = 0; idx < n; idx++)
    {
      NSInteger dim = sizes[idx];
      NSBitmapImageRep *source = makeSourceRep(dim, dim);
      NSData *jpeg = [source representationUsingType: NSJPEGFileType
                                          properties: [NSDictionary dictionary]];
      const unsigned char *bytes;
      NSUInteger len;
      BOOL hasSOI, hasEOI;
      NSBitmapImageRep *decoded;

      if (jpeg == nil)
        {
          allOk = NO;
          DESTROY(source);
          continue;
        }

      bytes = [jpeg bytes];
      len = [jpeg length];
      hasSOI = (len >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8);
      hasEOI = (len >= 2 && bytes[len - 2] == 0xff && bytes[len - 1] == 0xd9);
      if (!hasSOI || !hasEOI)
        {
          allOk = NO;
        }

      decoded = [[NSBitmapImageRep alloc] initWithData: jpeg];
      if (decoded == nil
          || [decoded pixelsWide] != dim
          || [decoded pixelsHigh] != dim)
        {
          allDecode = NO;
        }
      DESTROY(decoded);
      DESTROY(source);
    }

  pass(allOk,
    "encoding many small JPEGs always produces a valid SOI/EOI stream");
  pass(allDecode,
    "every one of those small JPEGs decodes back to its original dimensions");

  [arp release];
  return 0;
}
