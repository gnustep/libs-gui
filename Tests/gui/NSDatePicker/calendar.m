/* The clock and calendar style shows a month of days and a clock face, and
   the days can be picked with the mouse or walked with the arrow keys, a day
   across and a week up or down, which is how AppKit walks them.  The grid is
   seven columns wide and eight rows tall, a row for the name of the month, a
   row for the initials of the weekdays and six weeks, so a test can work out
   where a day sits from the size of the cell.  The set needs a display.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSDateFormatter.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSLocale.h>
#include <Foundation/NSString.h>
#include <Foundation/NSTimeZone.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSDatePickerCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>

static NSDateFormatter *fmt = nil;
static NSWindow *window = nil;

static NSDate *
clickCell(NSDatePicker *dp, int row, int column)
{
  NSSize size = [dp frame].size;
  CGFloat columnWidth = size.width / 7.0;
  CGFloat rowHeight = size.height / 8.0;
  NSPoint where;

  where.x = [dp frame].origin.x + (column + 0.5) * columnWidth;
  where.y = [dp frame].origin.y + size.height - (row + 2.5) * rowHeight;
  [dp mouseDown: [NSEvent mouseEventWithType: NSLeftMouseDown
                                    location: where
                               modifierFlags: 0
                                   timestamp: 0
                                windowNumber: [window windowNumber]
                                     context: nil
                                 eventNumber: 1
                                  clickCount: 1
                                    pressure: 1.0]];
  return [dp dateValue];
}

static void
key(NSDatePicker *dp, unichar c)
{
  NSString *characters = [NSString stringWithCharacters: &c length: 1];

  [dp keyDown: [NSEvent keyEventWithType: NSKeyDown
                                location: NSZeroPoint
                           modifierFlags: 0
                               timestamp: 0
                            windowNumber: 0
                                 context: nil
                              characters: characters
             charactersIgnoringModifiers: characters
                               isARepeat: NO
                                 keyCode: 0]];
}

static NSString *
value(NSDatePicker *dp)
{
  return [fmt stringFromDate: [dp dateValue]];
}

int
main(int argc, char **argv)
{
  NSDatePicker *dp;
  NSSize text;
  NSSize grid;
  NSDate *first;
  NSDate *second;

  START_SET("NSDatePicker calendar")

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
      fmt = [[NSDateFormatter alloc] init];
      [fmt setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
      [fmt setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [fmt setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US_POSIX"]];

      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 26)]);
      [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
      [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      [dp setDateValue: [fmt dateFromString: @"2023-03-08 20:26:40"]];

      text = [[dp cell] cellSize];
      [dp setDatePickerStyle: NSClockAndCalendarDatePickerStyle];
      grid = [[dp cell] cellSize];
      PASS(grid.height > text.height * 4.0 && grid.width > text.width,
           "the calendar style asks for room for a month of days");

      /* A frame the size of the cell puts the grid where the test looks
         for it. */
      [dp setFrameSize: grid];
      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, grid.width + 20,
                                        grid.height + 20)
                  styleMask: NSWindowStyleMaskTitled
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[window contentView] addSubview: dp];
      [window makeKeyAndOrderFront: nil];

      /* Drawing a month must work before anything is asked of the grid. */
      [dp lockFocus];
      [dp drawRect: [dp bounds]];
      [dp unlockFocus];

      /* The third row of the grid is inside the month whichever weekday
         the month starts on. */
      first = clickCell(dp, 2, 2);
      PASS(first != nil && [[value(dp) substringFromIndex: 11]
             isEqualToString: @"20:26:40"],
           "picking a day keeps the time of day");

      second = clickCell(dp, 2, 3);
      PASS([second timeIntervalSinceDate: first] == 86400.0,
           "the day to the right of one is the next day");

      first = second;
      second = clickCell(dp, 3, 3);
      PASS([second timeIntervalSinceDate: first] == 7.0 * 86400.0,
           "the day below one is a week later");

      /* The arrow keys walk the same grid. */
      [dp setDateValue: [fmt dateFromString: @"2023-03-08 20:26:40"]];
      key(dp, NSUpArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-03-01 20:26:40",
                 "the up arrow moves back a week");
      key(dp, NSDownArrowFunctionKey);
      key(dp, NSRightArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-03-09 20:26:40",
                 "the right arrow moves on a day");
      key(dp, NSLeftArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-03-08 20:26:40",
                 "the left arrow moves back a day");

      /* With the time elements as well there is a clock beside the month. */
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag
        | NSHourMinuteSecondDatePickerElementFlag];
      PASS([[dp cell] cellSize].width > grid.width,
           "the clock takes room of its own beside the month");
      [dp setFrameSize: [[dp cell] cellSize]];
      [dp lockFocus];
      [dp drawRect: [dp bounds]];
      [dp unlockFocus];
      PASS_EQUAL(value(dp), @"2023-03-08 20:26:40",
                 "drawing the clock leaves the date alone");
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

  END_SET("NSDatePicker calendar")

  return 0;
}
