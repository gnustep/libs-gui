#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSPDFImageRep.h>
#include <string.h>

/* When ImageMagick support is compiled in, -[NSPDFImageRep initWithData:]
   rasterised the PDF through GSImageMagickImageRep and then read the first
   page unconditionally, so a PDF that produced no page raised an out-of-range
   exception (gnustep/libs-gui issue #215; in a running application the
   uncaught exception surfaced as a blocking error panel).  Feed it data that
   cannot be rendered and check it fails softly with a zero size instead. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSPDFImageRep unrenderable data")

  const char *bytes = "%PDF-1.4\n1 0 obj<</Type/Catalog>>endobj\n%%EOF\n";
  NSData *pdfData = [NSData dataWithBytes: bytes length: strlen(bytes)];
  NSPDFImageRep *rep;

  rep = AUTORELEASE([[NSPDFImageRep alloc] initWithData: pdfData]);
  PASS(rep != nil,
    "initWithData: returns a representation for a PDF that yields no page");
  PASS(NSEqualSizes([rep size], NSMakeSize(0, 0)),
    "the size of an unrenderable PDF is zero");

  rep = AUTORELEASE([[NSPDFImageRep alloc] initWithData: [NSData data]]);
  PASS(rep != nil, "initWithData: handles empty data");

  END_SET("NSPDFImageRep unrenderable data")
  DESTROY(arp);
  return 0;
}
