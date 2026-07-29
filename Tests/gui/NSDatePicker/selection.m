/* While a date picker holds the keyboard it shows the part of the date the
   arrow keys act on the way selected text is shown, and the marking follows
   the arrow keys.  The picker has to be in a key window for that, so the set
   needs a display.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSDateFormatter.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSLocale.h>
#include <Foundation/NSRange.h>
#include <Foundation/NSString.h>
#include <Foundation/NSTimeZone.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSDatePickerCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>

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

/* The range the cell marks as selected, or a range of length zero. */
static NSRange
marked(NSDatePicker *dp)
{
  NSAttributedString *text = [[dp cell] attributedStringValue];
  NSRange range = NSMakeRange(0, 0);

  if ([text length] > 0)
    {
      NSUInteger index;

      for (index = 0; index < [text length]; index++)
        {
          if ([text attribute: NSBackgroundColorAttributeName
                      atIndex: index
               effectiveRange: NULL] != nil)
            {
              NSUInteger end = index;

              while (end < [text length]
                && [text attribute: NSBackgroundColorAttributeName
                           atIndex: end
                    effectiveRange: NULL] != nil)
                {
                  end++;
                }
              range = NSMakeRange(index, end - index);
              break;
            }
        }
    }

  return range;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSWindow *window;
  NSDatePicker *dp;
  NSString *text;
  NSRange range;

  START_SET("NSDatePicker selection")

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
      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 300, 60)
                  styleMask: NSWindowStyleMaskTitled
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(10, 10, 260, 26)]);
      [dp setLocale: [NSLocale localeWithLocaleIdentifier: @"en_US"]];
      [dp setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag];
      [dp setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate:
        700000000.0]];
      [[window contentView] addSubview: dp];

      PASS(marked(dp).length == 0,
           "a picker outside a key window marks nothing");

      [window makeKeyAndOrderFront: nil];
      [window makeFirstResponder: dp];
      if (![window isKeyWindow] || [window firstResponder] != dp)
        {
          SKIP("The window did not take the keyboard")
        }

      text = [[dp cell] stringValue];
      range = marked(dp);
      PASS(range.length > 0 && NSMaxRange(range) <= [text length],
           "the picker marks the part the arrow keys act on");
      PASS_EQUAL([text substringWithRange: range], @"3",
                 "the marked part of an American date is the month");

      key(dp, NSRightArrowFunctionKey);
      range = marked(dp);
      PASS_EQUAL([text substringWithRange: range], @"8",
                 "the right arrow marks the day");

      key(dp, NSRightArrowFunctionKey);
      range = marked(dp);
      PASS_EQUAL([text substringWithRange: range], @"2023",
                 "another right arrow marks the year");
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

  END_SET("NSDatePicker selection")

  DESTROY(arp);
  return 0;
}
