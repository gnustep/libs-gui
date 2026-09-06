/* In the mode that picks a range, the calendar marks every day the range
   covers rather than the one day the picker is set to.  The test counts the
   marked pixels in the drawn month, which grows with the range.  The set
   needs a display.
*/
#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSDateFormatter.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSLocale.h>
#include <Foundation/NSString.h>
#include <Foundation/NSTimeZone.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSDatePickerCell.h>
#include <AppKit/NSWindow.h>

/* How many pixels of the drawn picker carry the colour a marked day is
   filled with. */
static NSInteger
markedPixels(NSDatePicker *dp)
{
  NSBitmapImageRep *rep;
  NSColor *marked = [[NSColor selectedTextBackgroundColor]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  NSInteger count = 0;
  NSInteger x;
  NSInteger y;

  [dp lockFocus];
  /* Clear what the last draw left behind, which is what the window does
     for a picker that draws no background of its own. */
  [[NSColor whiteColor] set];
  NSRectFill([dp bounds]);
  [dp drawRect: [dp bounds]];
  rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithFocusedViewRect: [dp bounds]]);
  [dp unlockFocus];

  for (y = 0; y < [rep pixelsHigh]; y++)
    {
      for (x = 0; x < [rep pixelsWide]; x++)
        {
          NSColor *here = [[rep colorAtX: x y: y]
            colorUsingColorSpaceName: NSCalibratedRGBColorSpace];

          if (fabs([here redComponent] - [marked redComponent]) < 0.02
            && fabs([here greenComponent] - [marked greenComponent]) < 0.02
            && fabs([here blueComponent] - [marked blueComponent]) < 0.02)
            {
              count++;
            }
        }
    }

  return count;
}

int
main(int argc, char **argv)
{
  NSDateFormatter *fmt;
  NSWindow *window;
  NSDatePicker *dp;
  NSInteger single;
  NSInteger range;

  START_SET("NSDatePicker range")

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

  NS_DURING
    {
      fmt = AUTORELEASE([[NSDateFormatter alloc] init]);
      [fmt setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
      [fmt setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [fmt setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US_POSIX"]];

      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 150)]);
      [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
      [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [dp setDatePickerStyle: NSClockAndCalendarDatePickerStyle];
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      [dp setDateValue: [fmt dateFromString: @"2023-03-08 12:00:00"]];
      [dp setFrameSize: [[dp cell] cellSize]];

      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, [dp frame].size.width,
                                        [dp frame].size.height)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [window setContentView: dp];

      single = markedPixels(dp);
      PASS(single > 0, "the day a picker is set to is marked in the month");

      /* A range of four days covers the 8th to the 11th. */
      [dp setDatePickerMode: NSRangeDateMode];
      [dp setTimeInterval: 3.0 * 86400.0];
      range = markedPixels(dp);
      PASS(range > single * 2,
           "a range marks the days it covers, not just the first");

      PASS([[dp dateValue] isEqualToDate: [fmt dateFromString:
             @"2023-03-08 12:00:00"]] && [dp timeInterval] == 3.0 * 86400.0,
           "the range is the date the picker holds and its interval");

      /* Without an interval a range picker marks the one day again. */
      [dp setTimeInterval: 0.0];
      PASS(markedPixels(dp) == single,
           "a range of no length marks the one day");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSDatePicker range")

  return 0;
}
