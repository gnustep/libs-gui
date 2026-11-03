/* NSTextAlignment carries the same numbers as AppKit, which stores them in
   keyed archives and reads them back as raw integers.  The values below were
   read from a macOS runner: left 0, centre 1, right 2, justified 3 and
   natural 4. */
#import "Testing.h"
#import <Foundation/NSArchiver.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <AppKit/NSParagraphStyle.h>
#import <AppKit/NSText.h>

int
main(int argc, const char **argv)
{
  START_SET("NSTextAlignment values")

  NSMutableParagraphStyle *style;
  NSParagraphStyle *decoded;
  NSData *data;

  PASS(NSLeftTextAlignment == 0, "NSLeftTextAlignment is 0");
  PASS(NSCenterTextAlignment == 1, "NSCenterTextAlignment is 1");
  PASS(NSRightTextAlignment == 2, "NSRightTextAlignment is 2");
  PASS(NSJustifiedTextAlignment == 3, "NSJustifiedTextAlignment is 3");
  PASS(NSNaturalTextAlignment == 4, "NSNaturalTextAlignment is 4");

  PASS(NSTextAlignmentLeft == NSLeftTextAlignment
    && NSTextAlignmentCenter == NSCenterTextAlignment
    && NSTextAlignmentRight == NSRightTextAlignment
    && NSTextAlignmentJustified == NSJustifiedTextAlignment
    && NSTextAlignmentNatural == NSNaturalTextAlignment,
    "the current names have the values of the deprecated ones");

  PASS([NSParagraphStyle version] == 4,
    "the NSParagraphStyle class version records the change");

  style = AUTORELEASE([[NSMutableParagraphStyle alloc] init]);
  PASS([style alignment] == NSNaturalTextAlignment,
    "a new paragraph style is naturally aligned");

  [style setAlignment: NSRightTextAlignment];
  PASS([style alignment] == 2, "a right aligned paragraph style reads 2");

  data = [NSArchiver archivedDataWithRootObject: style];
  decoded = [NSUnarchiver unarchiveObjectWithData: data];
  PASS([decoded alignment] == NSRightTextAlignment,
    "the alignment survives an archive that is not keyed");

  [style setAlignment: NSCenterTextAlignment];
  data = [NSArchiver archivedDataWithRootObject: style];
  decoded = [NSUnarchiver unarchiveObjectWithData: data];
  PASS([decoded alignment] == NSCenterTextAlignment,
    "a centred paragraph style survives the same archive");

  END_SET("NSTextAlignment values")
  return 0;
}
