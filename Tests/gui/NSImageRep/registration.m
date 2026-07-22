/* Tests the NSImageRep class registry: the registered classes, the class
 * lookup by file type and by data, and registering and unregistering a class.
 * These are plain class-level operations.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSData.h>
#include <Foundation/NSString.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSImageRep.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSGraphics.h>

/* A minimal NSImageRep subclass used only to test registration. */
@interface TestImageRep : NSImageRep
@end
@implementation TestImageRep
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSImageRep registration")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  /* NSBitmapImageRep is registered by default. */
  PASS([[NSImageRep registeredImageRepClasses]
         containsObject: [NSBitmapImageRep class]],
    "NSBitmapImageRep is a registered image rep class");

  /* Class lookup by file type. */
  PASS([NSImageRep imageRepClassForFileType: @"tiff"] == [NSBitmapImageRep class],
    "the tiff file type maps to NSBitmapImageRep");
  PASS([NSImageRep imageRepClassForFileType: @"png"] == [NSBitmapImageRep class],
    "the png file type maps to NSBitmapImageRep");
  PASS([NSImageRep imageRepClassForFileType: @"bogustype"] == Nil,
    "an unknown file type maps to no class");

  /* Class lookup by data, using TIFF data produced from a bitmap. */
  {
    NSBitmapImageRep *bm = AUTORELEASE([[NSBitmapImageRep alloc]
      initWithBitmapDataPlanes: NULL
                    pixelsWide: 2
                    pixelsHigh: 2
                 bitsPerSample: 8
               samplesPerPixel: 3
                      hasAlpha: NO
                      isPlanar: NO
                colorSpaceName: NSDeviceRGBColorSpace
                   bytesPerRow: 0
                  bitsPerPixel: 0]);
    NSData *tiff = [bm TIFFRepresentation];
    NSData *garbage = [@"this is not an image"
                        dataUsingEncoding: NSUTF8StringEncoding];

    PASS([NSBitmapImageRep canInitWithData: tiff],
      "NSBitmapImageRep can init with tiff data");
    PASS([NSImageRep imageRepClassForData: tiff] == [NSBitmapImageRep class],
      "tiff data maps to NSBitmapImageRep");
    PASS([NSBitmapImageRep canInitWithData: garbage] == NO,
      "NSBitmapImageRep cannot init with non-image data");
    PASS([NSImageRep imageRepClassForData: garbage] == Nil,
      "non-image data maps to no class");
  }

  /* Registering adds the class once, and is idempotent; unregistering removes
   * it. */
  {
    NSUInteger before = [[NSImageRep registeredImageRepClasses] count];

    [NSImageRep registerImageRepClass: [TestImageRep class]];
    PASS([[NSImageRep registeredImageRepClasses] count] == before + 1
      && [[NSImageRep registeredImageRepClasses]
           containsObject: [TestImageRep class]],
      "registering a subclass adds it to the registry");

    [NSImageRep registerImageRepClass: [TestImageRep class]];
    PASS([[NSImageRep registeredImageRepClasses] count] == before + 1,
      "registering the same class again does not add it twice");

    [NSImageRep unregisterImageRepClass: [TestImageRep class]];
    PASS([[NSImageRep registeredImageRepClasses]
           containsObject: [TestImageRep class]] == NO
      && [[NSImageRep registeredImageRepClasses] count] == before,
      "unregistering removes the class from the registry");
  }

  END_SET("NSImageRep registration")

  DESTROY(arp);
  return 0;
}
