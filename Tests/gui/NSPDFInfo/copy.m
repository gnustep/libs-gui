/* -[NSPDFInfo copyWithZone:] returns a distinct copy that preserves the
   receiver's settable properties, rather than returning nil (which broke
   NSCopying). */
#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPDFInfo.h>

int main(int argc, const char **argv)
{
  START_SET("NSPDFInfo copy")

  NSPDFInfo *info = [[NSPDFInfo alloc] init];
  [info setFileExtensionHidden: YES];
  [info setOrientation: NSPaperOrientationLandscape];
  [info setPaperSize: NSMakeSize(100, 200)];

  NSPDFInfo *copy = [info copy];
  PASS(copy != nil, "-copy is non-nil");
  PASS(copy != info, "-copy is a distinct object");
  PASS([copy isFileExtensionHidden] == YES,
       "copy preserves fileExtensionHidden");
  PASS([copy orientation] == NSPaperOrientationLandscape,
       "copy preserves orientation");
  PASS(NSEqualSizes([copy paperSize], NSMakeSize(100, 200)),
       "copy preserves paperSize");

  RELEASE(info);
  RELEASE(copy);
  END_SET("NSPDFInfo copy")
  return 0;
}
