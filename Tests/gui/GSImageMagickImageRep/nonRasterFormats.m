#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <AppKit/NSImageRep.h>

/* GSImageMagickImageRep used to advertise every format ImageMagick knows,
   including document and vector formats that decode through an external
   delegate (PDF, PostScript) and formats with no decoder (HTML).  Loading
   those as images blocked or produced an empty representation
   (gnustep/libs-gui issue #215).  It should now claim only formats it can
   decode from a blob.  The class only exists when the GUI was built with
   ImageMagick, so look it up at runtime and skip otherwise. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("GSImageMagickImageRep non-raster formats")

  Class imageMagickRep = NSClassFromString(@"GSImageMagickImageRep");

  if (imageMagickRep == Nil)
    {
      SKIP("GNUstep GUI was built without ImageMagick support")
    }
  else
    {
      const unsigned char jpeg[] = {
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 'J', 'F', 'I', 'F', 0x00,
        0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB,
        0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08 };
      NSData *jpegData = [NSData dataWithBytes: jpeg length: sizeof(jpeg)];
      NSData *pdfData = [NSData dataWithBytes: "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n"
                                       length: 14];
      NSData *htmlData = [NSData dataWithBytes: "<html><head></head></html>"
                                       length: 26];
      NSArray *types = [imageMagickRep imageUnfilteredFileTypes];

      PASS([imageMagickRep canInitWithData: jpegData] == YES,
        "canInitWithData: accepts a raster format (JPEG)");
      PASS([imageMagickRep canInitWithData: pdfData] == NO,
        "canInitWithData: rejects a delegate format (PDF)");
      PASS([imageMagickRep canInitWithData: htmlData] == NO,
        "canInitWithData: rejects a format with no decoder (HTML)");

      PASS([types containsObject: @"jpeg"] || [types containsObject: @"jpg"],
        "imageUnfilteredFileTypes advertises a raster format");
      PASS(![types containsObject: @"pdf"],
        "imageUnfilteredFileTypes does not advertise pdf");
      PASS(![types containsObject: @"html"],
        "imageUnfilteredFileTypes does not advertise html");
    }

  END_SET("GSImageMagickImageRep non-raster formats")
  DESTROY(arp);
  return 0;
}
