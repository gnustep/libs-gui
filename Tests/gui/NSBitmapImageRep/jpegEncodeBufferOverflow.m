#import "ObjectTesting.h"
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphics.h>

/*
 * The JPEG destination manager sized its buffers as width * height *
 * components, i.e. the raw bitmap size, which is not an upper bound on the
 * encoded size (the headers alone are several hundred bytes).  Encoding a
 * small, noisy bitmap therefore wrote past the end of the heap buffer.
 */

static NSBitmapImageRep *
noisyRep(int width, int height, int samples, NSString *colorSpace)
{
  NSBitmapImageRep *rep;
  unsigned char *p;
  unsigned seed = 12345;
  int i, n;

  rep = [[NSBitmapImageRep alloc]
    initWithBitmapDataPlanes: NULL
                  pixelsWide: width
                  pixelsHigh: height
               bitsPerSample: 8
             samplesPerPixel: samples
                    hasAlpha: NO
                    isPlanar: NO
              colorSpaceName: colorSpace
                 bytesPerRow: 0
                bitsPerPixel: 0];
  p = [rep bitmapData];
  n = [rep bytesPerRow] * height;
  for (i = 0; i < n; i++)
    {
      seed = seed * 1103515245u + 12345u;
      p[i] = (unsigned char)(seed >> 16);
    }
  return rep;
}

static void
check(int width, int height, int samples, NSString *colorSpace)
{
  NSBitmapImageRep *rep = noisyRep(width, height, samples, colorSpace);
  NSData *jpeg;
  NSBitmapImageRep *decoded;

  jpeg = [rep representationUsingType: NSJPEGFileType properties: nil];
  PASS(jpeg != nil && [jpeg length] > 2,
    "encoding a %dx%d noisy bitmap with %d samples returns data",
    width, height, samples);

  if (jpeg != nil)
    {
      const unsigned char *b = [jpeg bytes];
      NSUInteger len = [jpeg length];

      PASS(len > 2 && b[0] == 0xFF && b[1] == 0xD8
        && b[len - 2] == 0xFF && b[len - 1] == 0xD9,
        "%dx%d output has JPEG SOI and EOI markers", width, height);

      decoded = [[NSBitmapImageRep alloc] initWithData: jpeg];
      PASS(decoded != nil && [decoded pixelsWide] == width
        && [decoded pixelsHigh] == height,
        "%dx%d output decodes with the original size", width, height);
      [decoded release];
    }
  [rep release];
}

int main()
{
  START_SET("NSBitmapImageRep jpegEncodeBufferOverflow")
  check(1, 1, 3, NSCalibratedRGBColorSpace);
  check(4, 4, 3, NSCalibratedRGBColorSpace);
  check(8, 8, 1, NSCalibratedWhiteColorSpace);
  check(16, 16, 3, NSCalibratedRGBColorSpace);
  check(256, 256, 3, NSCalibratedRGBColorSpace);
  END_SET("NSBitmapImageRep jpegEncodeBufferOverflow")
  return 0;
}
