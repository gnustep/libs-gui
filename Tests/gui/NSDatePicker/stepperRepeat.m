/* Holding a stepper button down goes on stepping.  The repeat is paced by
   periodic events, so the test puts two of them and the mouse up in the
   queue before the click and counts the steps that come out: one for the
   click and one for each periodic event.  The set needs a display.
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
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSDatePickerCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSWindow.h>

@interface Counter : NSObject
{
@public
  int actions;
}
@end

@implementation Counter
- (void) count: (id)sender
{
  actions++;
}
@end

static NSWindow *window = nil;

static NSEvent *
mouseEvent(NSEventType type, NSPoint where)
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

static NSEvent *
periodicEvent(void)
{
  return [NSEvent otherEventWithType: NSPeriodic
                            location: NSZeroPoint
                       modifierFlags: 0
                           timestamp: 0
                        windowNumber: [window windowNumber]
                             context: nil
                             subtype: 0
                               data1: 0
                               data2: 0];
}

int
main(int argc, char **argv)
{
  NSDatePicker *dp;
  NSDateFormatter *fmt;
  Counter *counter;
  CGFloat stepperWidth;
  NSPoint where;

  START_SET("NSDatePicker stepper repeat")

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

      stepperWidth = [[NSImage imageNamed: @"common_StepperUp"] size].width;
      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 60)
                  styleMask: NSWindowStyleMaskTitled
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      counter = AUTORELEASE([[Counter alloc] init]);
      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(10, 10, 200, 24)]);
      [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
      [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      [dp setDateValue: [fmt dateFromString: @"2023-03-08 20:26:40"]];
      [dp setTarget: counter];
      [dp setAction: @selector(count:)];
      [[window contentView] addSubview: dp];
      [window makeKeyAndOrderFront: nil];

      where = NSMakePoint([dp frame].origin.x + 200 - stepperWidth / 2,
                          [dp frame].origin.y + 20);

      [NSApp postEvent: periodicEvent() atStart: NO];
      [NSApp postEvent: periodicEvent() atStart: NO];
      [NSApp postEvent: mouseEvent(NSLeftMouseUp, where) atStart: NO];
      [dp mouseDown: mouseEvent(NSLeftMouseDown, where)];

      PASS_EQUAL([fmt stringFromDate: [dp dateValue]],
                 @"2023-06-08 20:26:40",
                 "the click steps once and each period steps again");
      PASS(counter->actions == 3, "every step sends the action");
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

  END_SET("NSDatePicker stepper repeat")

  return 0;
}
