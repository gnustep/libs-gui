/* Editing a date picker from the keyboard.  The arrow keys move between the
   parts of the date and step the part they are on, and a digit types into
   it.  The parts are those the locale writes, in the order it writes them,
   which for en_US is month, day, year, hour, minute, second and the
   morning/afternoon marker.  Every value here was checked against AppKit on
   a macOS runner.  The picker uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
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

@interface Counter : NSObject
{
@public
  int actions;
  NSDate *substitute;
}
@end

@implementation Counter
- (void) count: (id)sender
{
  actions++;
}
- (void) datePickerCell: (NSDatePickerCell *)cell
validateProposedDateValue: (NSDate **)proposed
           timeInterval: (NSTimeInterval *)interval
{
  if (substitute != nil)
    {
      *proposed = substitute;
    }
}
@end

static NSDateFormatter *fmt = nil;

static NSDatePicker *
picker(NSDatePickerElementFlags elements, NSString *when)
{
  NSDatePicker *dp = AUTORELEASE([[NSDatePicker alloc]
    initWithFrame: NSMakeRect(0, 0, 260, 26)]);

  [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
  [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
  [dp setDatePickerElements: elements];
  [dp setDateValue: [fmt dateFromString: when]];
  return dp;
}

static void
type(NSDatePicker *dp, NSString *characters)
{
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

static void
key(NSDatePicker *dp, unichar c)
{
  type(dp, [NSString stringWithCharacters: &c length: 1]);
}

static void
keys(NSDatePicker *dp, unichar c, int times)
{
  int i;

  for (i = 0; i < times; i++)
    {
      key(dp, c);
    }
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
  NSDatePickerElementFlags all;
  BOOL generator;

  START_SET("NSDatePicker keyboard")

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

      generator = ([NSDateFormatter dateFormatFromTemplate: @"yMd"
                                                   options: 0
                                                    locale: [NSLocale localeWithLocaleIdentifier: @"en_US"]]
                    != nil);
      all = NSYearMonthDayDatePickerElementFlag
        | NSHourMinuteSecondDatePickerElementFlag;

      /* The up arrow steps the part the picker is on, starting at the first
         part the locale writes. */
      dp = picker(all, @"2023-03-08 20:26:40");
      key(dp, NSUpArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-04-08 20:26:40",
                 "the up arrow steps the first part of the date");
      key(dp, NSDownArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-03-08 20:26:40",
                 "the down arrow steps it back");

      if (generator)
        {
          dp = picker(all, @"2023-03-08 20:26:40");
          keys(dp, NSRightArrowFunctionKey, 1);
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2023-03-09 20:26:40",
                     "the second part of an American date is the day");

          dp = picker(all, @"2023-03-08 20:26:40");
          keys(dp, NSRightArrowFunctionKey, 2);
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2024-03-08 20:26:40",
                     "the third part is the year");

          dp = picker(all, @"2023-03-08 20:26:40");
          keys(dp, NSRightArrowFunctionKey, 3);
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2023-03-08 21:26:40",
                     "the fourth part is the hour");

          dp = picker(all, @"2023-03-08 20:26:40");
          keys(dp, NSRightArrowFunctionKey, 4);
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2023-03-08 20:27:40",
                     "the fifth part is the minute");

          dp = picker(all, @"2023-03-08 20:26:40");
          keys(dp, NSRightArrowFunctionKey, 5);
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2023-03-08 20:26:41",
                     "the sixth part is the second");

          dp = picker(all, @"2023-03-08 20:26:40");
          keys(dp, NSRightArrowFunctionKey, 6);
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2023-03-08 08:26:40",
                     "the seventh part of an American time is the marker");

          dp = picker(all, @"2023-03-08 20:26:40");
          keys(dp, NSRightArrowFunctionKey, 7);
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2023-04-08 20:26:40",
                     "moving past the last part comes back to the first");

          dp = picker(all, @"2023-03-08 20:26:40");
          key(dp, NSLeftArrowFunctionKey);
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2023-03-08 08:26:40",
                     "moving left from the first part goes to the last");

          dp = picker(NSYearMonthDayDatePickerElementFlag,
                      @"2023-03-08 20:26:40");
          [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"de_DE"]];
          key(dp, NSUpArrowFunctionKey);
          PASS_EQUAL(value(dp), @"2023-03-09 20:26:40",
                     "the first part of a German date is the day");
        }

      /* A step is a step of the calendar, so it carries. */
      dp = picker(all, @"2023-12-08 20:26:40");
      key(dp, NSUpArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2024-01-08 20:26:40",
                 "a step past December carries into the year");

      dp = picker(all, @"2023-01-08 20:26:40");
      key(dp, NSDownArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2022-12-08 20:26:40",
                 "a step before January carries into the year");

      dp = picker(all, @"2023-03-31 20:26:40");
      key(dp, NSUpArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-04-30 20:26:40",
                 "a day the next month is too short for moves to its last day");

      /* Typing digits. */
      dp = picker(all, @"2023-03-08 20:26:40");
      type(dp, @"5");
      PASS_EQUAL(value(dp), @"2023-05-08 20:26:40",
                 "a digit no second digit can follow is taken on its own");

      dp = picker(all, @"2023-03-08 20:26:40");
      type(dp, @"1");
      PASS_EQUAL(value(dp), @"2023-03-08 20:26:40",
                 "a digit a second digit could follow waits for it");
      type(dp, @"2");
      PASS_EQUAL(value(dp), @"2023-12-08 20:26:40",
                 "the second digit completes the month");

      dp = picker(all, @"2023-03-08 20:26:40");
      type(dp, @"0");
      PASS_EQUAL(value(dp), @"2023-03-08 20:26:40",
                 "a leading zero leaves the date alone");

      /* The date limits hold for an edit from the keyboard. */
      dp = picker(all, @"2023-03-08 20:26:40");
      [dp setMaxDate: [fmt dateFromString: @"2023-03-20 00:00:00"]];
      key(dp, NSUpArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-03-20 00:00:00",
                 "a step beyond the maximum date stops at it");

      dp = picker(all, @"2023-03-08 20:26:40");
      [dp setMinDate: [fmt dateFromString: @"2023-03-01 00:00:00"]];
      key(dp, NSDownArrowFunctionKey);
      PASS_EQUAL(value(dp), @"2023-03-01 00:00:00",
                 "a step before the minimum date stops at it");

      /* The action goes out for an edit, and not for a date set in code. */
      {
        Counter *counter = AUTORELEASE([[Counter alloc] init]);

        dp = picker(all, @"2023-03-08 20:26:40");
        [dp setTarget: counter];
        [dp setAction: @selector(count:)];
        [dp setDateValue: [fmt dateFromString: @"2023-05-08 20:26:40"]];
        PASS(counter->actions == 0,
             "setting the date in code sends no action");
        key(dp, NSUpArrowFunctionKey);
        PASS(counter->actions == 1, "an edit sends the action once");
        type(dp, @"q");
        PASS(counter->actions == 1,
             "a key that means nothing to the picker sends no action");

        /* The delegate has the last word on the value. */
        [dp setDelegate: counter];
        counter->substitute = [fmt dateFromString: @"1999-09-09 09:09:09"];
        key(dp, NSUpArrowFunctionKey);
        PASS_EQUAL(value(dp), @"1999-09-09 09:09:09",
                   "the delegate can put another date in place of the edit");
      }
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

  END_SET("NSDatePicker keyboard")

  DESTROY(arp);
  return 0;
}
