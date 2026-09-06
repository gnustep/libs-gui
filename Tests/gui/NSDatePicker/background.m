/* A date picker that is asked to draw its background fills itself with the
   background colour it was given, and it draws its text in the text colour
   it was given.  The element flags keep only the bits AppKit keeps.  The
   drawing part needs a display, so the set is skipped without one.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSAttributedString.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSDatePicker.h>
#include <AppKit/NSDatePickerCell.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSWindow.h>

/* The colour a pixel near the trailing edge of the picker has, which is
   inside the frame but past the end of the text. */
static NSColor *
edgeColour(NSDatePicker *dp)
{
  NSBitmapImageRep *rep;
  NSSize size = [dp frame].size;

  [dp lockFocus];
  [dp drawRect: [dp bounds]];
  rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithFocusedViewRect: [dp bounds]]);
  [dp unlockFocus];

  return [[rep colorAtX: (NSInteger)size.width - 6
                      y: (NSInteger)size.height / 2]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
}

static BOOL
isRed(NSColor *colour)
{
  return (colour != nil && [colour redComponent] > 0.8
    && [colour greenComponent] < 0.2 && [colour blueComponent] < 0.2);
}

int
main(int argc, char **argv)
{
  NSWindow *window;
  NSDatePicker *dp;
  NSColor *textColour;

  START_SET("NSDatePicker background")

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
      dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 24)]);
      [dp setDatePickerStyle: NSTextFieldDatePickerStyle];
      [dp setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate:
        700000000.0]];

      /* The flags AppKit drops. */
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag
        | NSEraDatePickerElementFlag];
      PASS([dp datePickerElements] == NSYearMonthDayDatePickerElementFlag,
           "the era flag is not kept");
      [dp setDatePickerElements: NSEraDatePickerElementFlag];
      PASS([dp datePickerElements] == 0,
           "the era flag on its own leaves no elements");
      [dp setDatePickerElements: 0xffff];
      PASS([dp datePickerElements] == 0xff,
           "the flags above the documented ones are dropped");
      [dp setDatePickerElements: NSYearMonthDayDatePickerElementFlag
        | NSHourMinuteSecondDatePickerElementFlag];

      /* The text colour reaches the text that is drawn. */
      textColour = [NSColor blueColor];
      [dp setTextColor: textColour];
      PASS_EQUAL([[[dp cell] attributedStringValue]
                   attribute: NSForegroundColorAttributeName
                     atIndex: 0
              effectiveRange: NULL],
                 textColour,
                 "the text is drawn in the text colour of the picker");

      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 24)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [window setContentView: dp];

      [dp setBackgroundColor: [NSColor redColor]];
      [dp setDrawsBackground: NO];
      PASS(!isRed(edgeColour(dp)),
           "a picker that draws no background is not filled");

      [dp setDrawsBackground: YES];
      PASS(isRed(edgeColour(dp)),
           "a picker that draws its background is filled with it");
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

  END_SET("NSDatePicker background")

  return 0;
}
