/* What a date picker tells the rest of the framework about itself: the size
   it wants, which follows the style and the elements it shows, and what a
   click on it means.  Dragging across the month sets how long a range is.
   The set needs a display.
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
#include <AppKit/NSCell.h>
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSDatePickerCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>

static NSWindow *window = nil;

static NSEvent *
mouseAt(NSEventType type, NSPoint where)
{
  return [NSEvent mouseEventWithType: type
                            location: where
                       modifierFlags: 0
                           timestamp: 0
                        windowNumber: [window windowNumber]
                             context: nil
                         eventNumber: 1
                          clickCount: 1
                            pressure: (type == NSLeftMouseUp) ? 0.0 : 1.0];
}

/* The middle of a day cell of the drawn month, in window coordinates.  The
   grid is seven columns and eight rows of the cell size. */
static NSPoint
dayCentre(NSDatePicker *dp, int row, int column)
{
  NSSize size = [dp frame].size;

  return NSMakePoint([dp frame].origin.x + (column + 0.5) * size.width / 7.0,
                     [dp frame].origin.y + size.height
                       - (row + 2.5) * size.height / 8.0);
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSDateFormatter *fmt;
  NSDatePicker *dp;
  NSSize text;
  NSSize calendar;
  NSDate *clicked;

  START_SET("NSDatePicker metrics")

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
        initWithFrame: NSMakeRect(0, 0, 400, 300)]);
      [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
      [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      [dp setDateValue: [fmt dateFromString: @"2023-03-08 12:00:00"]];

      /* The size it asks for is the size of what it draws, whatever frame
         it happens to have. */
      text = [dp intrinsicContentSize];
      PASS(text.width > 0.0 && text.height > 0.0
           && !NSEqualSizes(text, [dp frame].size),
           "a picker asks for the size of what it draws, not its frame");
      PASS(NSEqualSizes(text, [[dp cell] cellSize]),
           "the size it asks for is the size of its cell");

      [dp setDatePickerStyle: NSClockAndCalendarDatePickerStyle];
      calendar = [dp intrinsicContentSize];
      PASS(calendar.height > text.height * 4.0 && calendar.width > text.width,
           "the calendar style asks for room for a month");

      /* A click on a picker is content, editable text and trackable at
         once. */
      PASS([[dp cell] hitTestForEvent: mouseAt(NSLeftMouseDown, NSZeroPoint)
                               inRect: [dp bounds]
                               ofView: dp]
             == (NSCellHitContentArea | NSCellHitEditableTextArea
                 | NSCellHitTrackableArea),
           "a click on a picker hits text that can be edited and tracked");
      [[dp cell] setEnabled: NO];
      PASS([[dp cell] hitTestForEvent: mouseAt(NSLeftMouseDown, NSZeroPoint)
                               inRect: [dp bounds]
                               ofView: dp]
             == NSCellHitContentArea,
           "a picker that is turned off is content and nothing more");
      [[dp cell] setEnabled: YES];

      /* Dragging across the month sets the length of a range. */
      [dp setFrameSize: calendar];
      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, calendar.width + 20,
                                        calendar.height + 20)
                  styleMask: NSWindowStyleMaskTitled
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[window contentView] addSubview: dp];
      [window makeKeyAndOrderFront: nil];
      [dp setDatePickerMode: NSRangeDateMode];
      [dp setTimeInterval: 0.0];

      /* Where a plain click on that day lands, to compare the drag with. */
      [NSApp postEvent: mouseAt(NSLeftMouseUp, dayCentre(dp, 2, 2))
               atStart: NO];
      [dp mouseDown: mouseAt(NSLeftMouseDown, dayCentre(dp, 2, 2))];
      clicked = [dp dateValue];
      [dp setTimeInterval: 0.0];

      [NSApp postEvent: mouseAt(NSLeftMouseDragged, dayCentre(dp, 2, 5))
               atStart: NO];
      [NSApp postEvent: mouseAt(NSLeftMouseUp, dayCentre(dp, 2, 5))
               atStart: NO];
      [dp mouseDown: mouseAt(NSLeftMouseDown, dayCentre(dp, 2, 2))];

      PASS([dp timeInterval] == 3.0 * 86400.0,
           "dragging three days on makes the range three days long");
      PASS_EQUAL([dp dateValue], clicked,
                 "the day the drag started at is where the range starts");

      /* A drag back before the start leaves nothing selected. */
      [dp setTimeInterval: 0.0];
      [NSApp postEvent: mouseAt(NSLeftMouseDragged, dayCentre(dp, 2, 0))
               atStart: NO];
      [NSApp postEvent: mouseAt(NSLeftMouseUp, dayCentre(dp, 2, 0))
               atStart: NO];
      [dp mouseDown: mouseAt(NSLeftMouseDown, dayCentre(dp, 2, 2))];
      PASS([dp timeInterval] == 0.0,
           "dragging back before the start leaves the range empty");
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

  END_SET("NSDatePicker metrics")

  DESTROY(arp);
  return 0;
}
