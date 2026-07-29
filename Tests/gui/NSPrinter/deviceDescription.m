/* NSDeviceResolution holds an NSValue with an NSSize, as it does in the device
   description of a screen and as -[NSImage bestRepresentationForDevice:] reads
   it.  A PPD resolution reads '600dpi' or '600x300dpi'; a keyword naming no
   resolution at all, such as the 'default' of the shipped generic PPD, leaves
   the entry out.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSPrinter.h>

static NSString *ppdFormat =
  @"*PPD-Adobe: \"4.3\"\n"
  @"*ModelName: \"Test\"\n"
  @"*ColorDevice: False\n"
  @"*DefaultResolution: %@\n"
  @"*DefaultPageSize: Letter\n"
  @"*PaperDimension Letter/US Letter: \"612 792\"\n";

static NSPrinter *printerWithResolution(NSString *resolution, NSString *path)
{
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSDictionary *entry;
  NSPrinter *printer = nil;

  if (![[NSString stringWithFormat: ppdFormat, resolution]
         writeToFile: path atomically: YES])
    {
      return nil;
    }

  entry = [NSDictionary dictionaryWithObjectsAndKeys:
    path, @"PPDPath",
    @"localhost", @"Host",
    resolution, @"Type",
    @"test", @"Note",
    nil];

  [ud setObject: @"GSLPR" forKey: @"GSPrinting"];
  [ud setObject: [NSDictionary dictionaryWithObject: entry
                                             forKey: resolution]
         forKey: @"GSLPRPrinters"];

  NS_DURING
    {
      printer = [NSPrinter printerWithName: resolution];
    }
  NS_HANDLER
    {
      printer = nil;
    }
  NS_ENDHANDLER

  return printer;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSPrinter device description")

  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  id savedPrinters = [ud objectForKey: @"GSLPRPrinters"];
  id savedBundle = [ud objectForKey: @"GSPrinting"];
  NSString *path;
  NSPrinter *printer;
  NSDictionary *description;
  id resolution;

  path = [NSTemporaryDirectory()
           stringByAppendingPathComponent: @"gsDeviceDescription.ppd"];

  printer = printerWithResolution(@"600dpi", path);

  if (printer == nil)
    {
      SKIP("no printing bundle able to read a PPD")
    }

  description = [printer deviceDescription];
  resolution = [description objectForKey: NSDeviceResolution];

  PASS([resolution respondsToSelector: @selector(sizeValue)],
       "NSDeviceResolution of a printer holds a size");

  PASS(NSEqualSizes([resolution sizeValue], NSMakeSize(600, 600)),
       "a resolution of 600dpi is 600 by 600");

  PASS(NSEqualSizes([[description objectForKey: NSDeviceSize] sizeValue],
                    NSMakeSize(612, 792)),
       "NSDeviceSize is the size of the default paper");

  /* The documented consumer of a device description. */
  {
    NSImage *image;
    NSBitmapImageRep *rep;
    NSImageRep *best = nil;
    BOOL raised = NO;

    image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);
    rep = AUTORELEASE([[NSBitmapImageRep alloc]
                        initWithBitmapDataPlanes: NULL
                                      pixelsWide: 16
                                      pixelsHigh: 16
                                   bitsPerSample: 8
                                 samplesPerPixel: 3
                                        hasAlpha: NO
                                        isPlanar: NO
                                  colorSpaceName: NSDeviceRGBColorSpace
                                     bytesPerRow: 0
                                    bitsPerPixel: 0]);
    [image addRepresentation: rep];

    NS_DURING
      {
        best = [image bestRepresentationForDevice: description];
      }
    NS_HANDLER
      {
        raised = YES;
      }
    NS_ENDHANDLER

    PASS(raised == NO,
         "asking an image for its best representation for a printer does not "
         "raise");
    PASS_EQUAL(best, rep,
               "the representation of the image is returned");
  }

  printer = printerWithResolution(@"600x300dpi", path);
  resolution = [[printer deviceDescription] objectForKey: NSDeviceResolution];

  PASS(NSEqualSizes([resolution sizeValue], NSMakeSize(600, 300)),
       "an asymmetric resolution keeps both directions");

  printer = printerWithResolution(@"default", path);

  PASS([[printer deviceDescription] objectForKey: NSDeviceResolution] == nil,
       "a keyword naming no resolution leaves NSDeviceResolution out");

  [[NSFileManager defaultManager] removeFileAtPath: path handler: nil];

  if (savedPrinters != nil)
    [ud setObject: savedPrinters forKey: @"GSLPRPrinters"];
  else
    [ud removeObjectForKey: @"GSLPRPrinters"];

  if (savedBundle != nil)
    [ud setObject: savedBundle forKey: @"GSPrinting"];
  else
    [ud removeObjectForKey: @"GSPrinting"];

  END_SET("NSPrinter device description")

  DESTROY(arp);
  return 0;
}
