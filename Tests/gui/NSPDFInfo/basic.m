/* Coverage for NSPDFInfo: the NSPaperOrientation enum, the init defaults that
   match AppKit (nil URL, portrait orientation), the fileExtensionHidden /
   orientation / paperSize setters, and the NSCoding / NSCopying conformance.
   Every assertion was checked against Apple AppKit (macOS 26) and matches.
   NSPDFInfo is a plain model object and needs no backend. */
#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSPrintInfo.h>
#import <AppKit/NSPDFInfo.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  /* Enum values match AppKit. */
  PASS(NSPaperOrientationPortrait == 0, "NSPaperOrientationPortrait is 0");
  PASS(NSPaperOrientationLandscape == 1, "NSPaperOrientationLandscape is 1");

  NSPDFInfo *info = [[NSPDFInfo alloc] init];
  PASS(info != nil, "NSPDFInfo -init returns an instance");

  /* Defaults that match AppKit. */
  PASS([info URL] == nil, "default URL is nil");
  PASS([info orientation] == NSPaperOrientationPortrait,
       "default orientation is portrait");

  /* Setters round-trip. */
  [info setFileExtensionHidden: YES];
  PASS([info isFileExtensionHidden] == YES, "setFileExtensionHidden: round-trips");

  [info setOrientation: NSPaperOrientationLandscape];
  PASS([info orientation] == NSPaperOrientationLandscape,
       "setOrientation: round-trips");

  [info setPaperSize: NSMakeSize(612, 792)];
  PASS(NSEqualSizes([info paperSize], NSMakeSize(612, 792)),
       "setPaperSize: round-trips");

  /* Declared protocol conformance. */
  PASS([info conformsToProtocol: @protocol(NSCoding)], "conforms to NSCoding");
  PASS([info conformsToProtocol: @protocol(NSCopying)], "conforms to NSCopying");

  RELEASE(info);
  DESTROY(arp);
  return 0;
}
