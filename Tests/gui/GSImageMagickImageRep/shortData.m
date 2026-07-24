#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <AppKit/NSBitmapImageRep.h>

/* GSImageMagickImageRep probed the last bytes of the data for a Targa
   signature with a fixed-length range, which underflowed and raised an
   out-of-range exception for data shorter than that probe (gnustep/libs-gui
   issue #215).  Feed it such data and check it returns no representations
   instead of raising.  The class only exists when the GUI was built with
   ImageMagick, so look it up at runtime and skip otherwise. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("GSImageMagickImageRep short data")

  Class imageMagickRep = NSClassFromString(@"GSImageMagickImageRep");

  if (imageMagickRep == Nil)
    {
      SKIP("GNUstep GUI was built without ImageMagick support")
    }
  else
    {
      NSData *shortData = [NSData dataWithBytes: "abc" length: 3];
      NSData *emptyData = [NSData data];
      NSArray *reps;

      reps = [imageMagickRep performSelector: @selector(imageRepsWithData:)
                                  withObject: shortData];
      PASS(reps != nil && [reps count] == 0,
        "imageRepsWithData: returns no reps for data shorter than the "
        "signature probe");

      reps = [imageMagickRep performSelector: @selector(imageRepsWithData:)
                                  withObject: emptyData];
      PASS([reps count] == 0,
        "imageRepsWithData: handles empty data");
    }

  END_SET("GSImageMagickImageRep short data")
  DESTROY(arp);
  return 0;
}
