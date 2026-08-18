#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSString.h>
#import <AppKit/NSImageRep.h>
#import <AppKit/NSPDFImageRep.h>

/* Build a PDF of pageCount empty pages, page n carrying the media box
   sizes[n], with an xref table of the right offsets. */
static NSData *
pdfWithPageSizes(const NSSize *sizes, unsigned pageCount)
{
  NSMutableData *pdf = [NSMutableData data];
  NSMutableString *kids = [NSMutableString string];
  unsigned offsets[16];
  unsigned objects = 0;
  NSString *text;
  unsigned xref;
  unsigned i;

  for (i = 0; i < pageCount; i++)
    [kids appendFormat: @"%u 0 R ", i + 3];

  [pdf appendBytes: "%PDF-1.4\n" length: 9];

  offsets[objects++] = [pdf length];
  text = @"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n";
  [pdf appendData: [text dataUsingEncoding: NSASCIIStringEncoding]];

  offsets[objects++] = [pdf length];
  text = [NSString stringWithFormat:
    @"2 0 obj\n<< /Type /Pages /Kids [%@] /Count %u >>\nendobj\n",
    kids, pageCount];
  [pdf appendData: [text dataUsingEncoding: NSASCIIStringEncoding]];

  for (i = 0; i < pageCount; i++)
    {
      offsets[objects++] = (unsigned)[pdf length];
      text = [NSString stringWithFormat:
        @"%u 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %d %d] "
        @"/Resources << >> >>\nendobj\n",
        i + 3, (int)sizes[i].width, (int)sizes[i].height];
      [pdf appendData: [text dataUsingEncoding: NSASCIIStringEncoding]];
    }

  xref = [pdf length];
  text = [NSString stringWithFormat: @"xref\n0 %u\n0000000000 65535 f \n",
                   pageCount + 3];
  [pdf appendData: [text dataUsingEncoding: NSASCIIStringEncoding]];
  for (i = 0; i < objects; i++)
    {
      text = [NSString stringWithFormat: @"%010u 00000 n \n", offsets[i]];
      [pdf appendData: [text dataUsingEncoding: NSASCIIStringEncoding]];
    }
  text = [NSString stringWithFormat:
    @"trailer\n<< /Size %u /Root 1 0 R >>\nstartxref\n%u\n%%%%EOF\n",
    pageCount + 3, xref];
  [pdf appendData: [text dataUsingEncoding: NSASCIIStringEncoding]];

  return pdf;
}

int
main(int argc, const char **argv)
{
  START_SET("NSPDFImageRep page selection")

  const NSSize sizes[3] = {{200, 100}, {400, 300}, {100, 50}};
  NSData *pdfData = pdfWithPageSizes(sizes, 3);
  NSPDFImageRep *rep;

  rep = AUTORELEASE([[NSPDFImageRep alloc] initWithData: pdfData]);
  if ([rep pageCount] == 0)
    {
      SKIP("this build renders no PDF page")
    }
  else
    {
      PASS([rep pageCount] == 3, "pageCount is the number of pages");
      PASS(NSEqualSizes([rep size], NSMakeSize(200, 100)),
        "a new representation takes its size from the first page");
      PASS([rep currentPage] == 0, "a new representation is on page 0");
      PASS([rep pixelsWide] == NSImageRepMatchesDevice
        && [rep pixelsHigh] == NSImageRepMatchesDevice,
        "a new representation has no pixel size");

      [rep setCurrentPage: 1];
      PASS([rep currentPage] == 1, "setCurrentPage: 1 selects the second page");
      PASS(NSEqualSizes([rep size], NSMakeSize(400, 300)),
        "size follows the selected page");
      PASS([rep pixelsWide] == 400 && [rep pixelsHigh] == 300,
        "the pixel size follows the selected page");
      PASS(NSEqualRects([rep bounds], NSMakeRect(0, 0, 400, 300)),
        "bounds follow the selected page");

      [rep setCurrentPage: 2];
      PASS(NSEqualSizes([rep size], NSMakeSize(100, 50)),
        "the third page is 100 by 50");
      PASS([rep pixelsWide] == 100 && [rep pixelsHigh] == 50,
        "the pixel size of the third page is 100 by 50");

      [rep setCurrentPage: 3];
      PASS([rep currentPage] == 2,
        "setCurrentPage: past the last page selects the last page");
      PASS([rep pixelsWide] == 100 && [rep pixelsHigh] == 50,
        "the pixel size stays on the last page");

      [rep setCurrentPage: -1];
      PASS([rep currentPage] == 0,
        "setCurrentPage: below zero selects the first page");
      PASS([rep pixelsWide] == 200 && [rep pixelsHigh] == 100,
        "the pixel size returns to the first page");
    }

  END_SET("NSPDFImageRep page selection")

  START_SET("NSPDFImageRep drawing the first page")

  const NSSize one[1] = {{200, 100}};
  NSPDFImageRep *rep
    = AUTORELEASE([[NSPDFImageRep alloc] initWithData: pdfWithPageSizes(one, 1)]);
  NSString *raised = nil;

  if ([rep pageCount] == 0)
    {
      SKIP("this build renders no PDF page")
    }
  else
    {
      [rep setCurrentPage: 0];
      NS_DURING
        [rep draw];
      NS_HANDLER
        raised = [localException name];
      NS_ENDHANDLER
      PASS(![raised isEqualToString: NSRangeException],
        "-draw on page 0 stays inside the page list");
    }

  END_SET("NSPDFImageRep drawing the first page")
  return 0;
}
