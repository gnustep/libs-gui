/* Coverage for the NSPrintInfo dictionary-backed accessors: the defaults
   set up by -initWithDictionary:, the paper name/size relationship, the
   way -setPaperSize: and -setOrientation: keep the size and orientation
   consistent, the margin/pagination/centering/jobDisposition accessors,
   the overlay done by -initWithDictionary:, and -copy independence.
   Concrete paper dimensions are not hard-coded here because they come
   from the default printer; the tests check them against
   +sizeForPaperName: instead.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSPrintInfo.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSPrintInfo *info;
  NSSize size;

  START_SET("NSPrintInfo dictionary")

  /* Defaults from -initWithDictionary: nil. */
  info = AUTORELEASE([[NSPrintInfo alloc] initWithDictionary: nil]);
  PASS([info orientation] == NSPortraitOrientation, "default orientation is portrait");
  PASS([info horizontalPagination] == NSClipPagination, "default horizontal pagination is clip");
  PASS([info verticalPagination] == NSAutoPagination, "default vertical pagination is auto");
  PASS([[info jobDisposition] isEqualToString: NSPrintSpoolJob], "default job disposition is spool");
  PASS([info paperName] != nil, "a default paper name is set");
  PASS(NSEqualSizes([info paperSize],
                    [NSPrintInfo sizeForPaperName: [info paperName]]),
       "default paper size matches the default paper name");

  /* -setPaperName: pulls the size from +sizeForPaperName:. */
  [info setPaperName: @"A4"];
  size = [NSPrintInfo sizeForPaperName: @"A4"];
  PASS([[info paperName] isEqualToString: @"A4"], "setPaperName: stores the name");
  PASS(NSEqualSizes([info paperSize], size), "setPaperName: sets the matching size");
  PASS(size.width > 0 && size.height > 0, "A4 has a positive size");
  PASS(size.width < size.height, "A4 is taller than it is wide");

  /* -setPaperSize: derives the orientation from the aspect. */
  [info setPaperSize: NSMakeSize(800.0, 400.0)];
  PASS(NSEqualSizes([info paperSize], NSMakeSize(800.0, 400.0)), "setPaperSize: stores the size");
  PASS([info orientation] == NSLandscapeOrientation, "a wide paper is landscape");
  [info setPaperSize: NSMakeSize(300.0, 900.0)];
  PASS([info orientation] == NSPortraitOrientation, "a tall paper is portrait");
  [info setPaperSize: NSMakeSize(500.0, 500.0)];
  PASS([info orientation] == NSPortraitOrientation, "a square paper is portrait");

  /* -setOrientation: swaps the dimensions to match. */
  info = AUTORELEASE([[NSPrintInfo alloc] initWithDictionary: nil]);
  [info setPaperSize: NSMakeSize(400.0, 800.0)]; /* portrait */
  [info setOrientation: NSLandscapeOrientation];
  PASS([info orientation] == NSLandscapeOrientation, "orientation is now landscape");
  PASS(NSEqualSizes([info paperSize], NSMakeSize(800.0, 400.0)),
       "switching to landscape swaps the dimensions");
  [info setOrientation: NSPortraitOrientation];
  PASS(NSEqualSizes([info paperSize], NSMakeSize(400.0, 800.0)),
       "switching back to portrait swaps them again");

  /* Margins are stored and read back verbatim. */
  [info setLeftMargin: 11.0];
  [info setRightMargin: 12.0];
  [info setTopMargin: 13.0];
  [info setBottomMargin: 14.0];
  PASS([info leftMargin] == 11.0, "left margin round trips");
  PASS([info rightMargin] == 12.0, "right margin round trips");
  PASS([info topMargin] == 13.0, "top margin round trips");
  PASS([info bottomMargin] == 14.0, "bottom margin round trips");

  /* Pagination and centering accessors. */
  [info setHorizontalPagination: NSFitPagination];
  [info setVerticalPagination: NSClipPagination];
  PASS([info horizontalPagination] == NSFitPagination, "horizontal pagination round trips");
  PASS([info verticalPagination] == NSClipPagination, "vertical pagination round trips");
  [info setHorizontallyCentered: YES];
  [info setVerticallyCentered: YES];
  PASS([info isHorizontallyCentered] == YES, "horizontal centering round trips");
  PASS([info isVerticallyCentered] == YES, "vertical centering round trips");

  /* Job disposition. */
  [info setJobDisposition: NSPrintPreviewJob];
  PASS([[info jobDisposition] isEqualToString: NSPrintPreviewJob], "job disposition round trips");

  /* The dictionary exposes the same values under the NSPrint* keys. */
  [info setLeftMargin: 42.0];
  PASS([[[info dictionary] objectForKey: NSPrintLeftMargin] doubleValue] == 42.0,
       "the dictionary reflects a changed margin");

  /* -initWithDictionary: overlays the supplied entries onto the defaults. */
  {
    NSMutableDictionary *seed = [NSMutableDictionary dictionary];
    NSPrintInfo *seeded;

    [seed setObject: [NSNumber numberWithDouble: 99.0] forKey: NSPrintLeftMargin];
    seeded = AUTORELEASE([[NSPrintInfo alloc] initWithDictionary: seed]);
    PASS([seeded leftMargin] == 99.0, "initWithDictionary: overlays the supplied entries");
    PASS([[seeded jobDisposition] isEqualToString: NSPrintSpoolJob],
         "initWithDictionary: keeps the defaults for keys not supplied");
  }

  /* -copy is independent of the original. */
  {
    NSPrintInfo *dup;

    [info setLeftMargin: 5.0];
    dup = [info copy];
    [dup setLeftMargin: 500.0];
    PASS([info leftMargin] == 5.0, "mutating the copy leaves the original unchanged");
    PASS([dup leftMargin] == 500.0, "the copy keeps its own value");
    RELEASE(dup);
  }

  END_SET("NSPrintInfo dictionary")

  DESTROY(arp);
  return 0;
}
