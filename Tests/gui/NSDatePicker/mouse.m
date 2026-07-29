/* Clicking a date picker takes the keyboard, picks the part of the date
   under the pointer, and steps that part when the click is on the stepper of
   the text field and stepper style.  The picker has to be in a key window,
   so the set needs a display.
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

static NSDateFormatter *fmt = nil;
static NSWindow *window = nil;

/* A click on the stepper keeps stepping while the button is held, so the
   matching mouse up has to be waiting in the queue before the click. */
static void
click(NSDatePicker *dp, NSPoint inside)
{
  NSPoint where = NSMakePoint([dp frame].origin.x + inside.x,
                              [dp frame].origin.y + inside.y);

  [NSApp postEvent: [NSEvent mouseEventWithType: NSLeftMouseUp
                                       location: where
                                  modifierFlags: 0
                                      timestamp: 0
                                   windowNumber: [window windowNumber]
                                        context: nil
                                    eventNumber: 2
                                     clickCount: 1
                                       pressure: 0.0]
           atStart: NO];
  [dp mouseDown: [NSEvent mouseEventWithType: NSLeftMouseDown
                                    location: where
                               modifierFlags: 0
                                   timestamp: 0
                                windowNumber: [window windowNumber]
                                     context: nil
                                 eventNumber: 1
                                  clickCount: 1
                                    pressure: 1.0]];
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
  CREATE_AUTORELEASE_POOL(arp);
  NSDatePicker *dp;
  Counter *counter;
  CGFloat stepperWidth;
  CGFloat height = 26.0;
  CGFloat width = 200.0;

  START_SET("NSDatePicker mouse")

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

      stepperWidth = [[NSImage imageNamed: @"common_StepperUp"] size].width;
      PASS(stepperWidth > 0.0, "the theme has a stepper image");

      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 60)
                  styleMask: NSWindowStyleMaskTitled
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      counter = AUTORELEASE([[Counter alloc] init]);
      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(10, 10, width, height)]);
      [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
      [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      [dp setDateValue: [fmt dateFromString: @"2023-03-08 20:26:40"]];
      [dp setTarget: counter];
      [dp setAction: @selector(count:)];
      [[window contentView] addSubview: dp];
      [window makeKeyAndOrderFront: nil];

      /* A click in the text takes the keyboard and changes nothing. */
      click(dp, NSMakePoint(4, height / 2));
      if ([window firstResponder] != dp)
        {
          SKIP("The window did not take the keyboard")
        }
      PASS_EQUAL(value(dp), @"2023-03-08 20:26:40",
                 "a click in the text leaves the date alone");
      PASS(counter->actions == 0, "a click in the text sends no action");

      /* The part under the pointer is the one the arrow keys act on. */
      key(dp, NSUpArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-04-08 20:26:40",
                 "a click at the left edge picks the first part of the date");

      click(dp, NSMakePoint(width - stepperWidth - 2, height / 2));
      key(dp, NSUpArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2024-04-08 20:26:40",
                 "a click at the right of the text picks the last part");

      /* The stepper steps the part that is picked. */
      counter->actions = 0;
      click(dp, NSMakePoint(width - stepperWidth / 2, height - 4));
      PASS_EQUAL(value(dp), @"2025-04-08 20:26:40",
                 "the upper half of the stepper steps the part up");
      PASS(counter->actions == 1, "a step from the stepper sends the action");

      click(dp, NSMakePoint(width - stepperWidth / 2, 4));
      PASS_EQUAL(value(dp), @"2024-04-08 20:26:40",
                 "the lower half of the stepper steps the part down");

      /* The style without a stepper has none to click. */
      [dp setDatePickerStyle: NSTextFieldDatePickerStyle];
      click(dp, NSMakePoint(width - stepperWidth / 2, height - 4));
      PASS_EQUAL(value(dp), @"2024-04-08 20:26:40",
                 "the text field style has no stepper to step with");
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

  END_SET("NSDatePicker mouse")

  DESTROY(arp);
  return 0;
}
