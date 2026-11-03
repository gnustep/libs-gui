/* A cell's size has to be whole numbers.  With a scale factor other than one
   the text measurement is fractional, and a control sized to the fraction has
   less room than its text needs and loses the last glyph, which is what
   gnustep/libs-gui#280 is about.  The scale factor has to be set before the
   font is built, so it goes in before the application is created. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTextFieldCell.h>

static BOOL
isWhole(CGFloat v)
{
  return v == (CGFloat)(long)v;
}

int
main(int argc, const char **argv)
{
  NSTextFieldCell *cell;
  NSSize size;

  START_SET("NSCell size with a scale factor")

  [[NSUserDefaults standardUserDefaults]
    setObject: [NSNumber numberWithDouble: 1.5]
       forKey: @"GSScaleFactor"];

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      cell = AUTORELEASE([[NSTextFieldCell alloc] initTextCell: @"Alert"]);
      size = [cell cellSize];
      PASS(isWhole(size.width) && isWhole(size.height),
	"a text cell's size is whole numbers at a scale factor of 1.5");
      PASS(size.width > 0 && size.height > 0,
	"a text cell with a string has a size");

      cell = AUTORELEASE([[NSTextFieldCell alloc]
	initTextCell: @"Widths and heights"]);
      size = [cell cellSize];
      PASS(isWhole(size.width) && isWhole(size.height),
	"a longer string also gives whole numbers");

      cell = AUTORELEASE([[NSTextFieldCell alloc] initTextCell: @""]);
      size = [cell cellSize];
      PASS(isWhole(size.width) && isWhole(size.height),
	"an empty text cell gives whole numbers too");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSCell size with a scale factor")

  return 0;
}
