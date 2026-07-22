/* The displacement of a pushed-in button's contents is controlled by the theme
   through -[GSTheme buttonPushInOffsetForCell:], so a theme can change or
   suppress it (gnustep/libs-gui#219).  The default is one pixel to the bottom
   right, and -[NSButtonCell drawingRectForBounds:] offsets the interior by that
   amount while the button is highlighted.  Laying out the cell needs the theme,
   so the body is guarded. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSButtonCell.h>
#import <GNUstepGUI/GSTheme.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSButtonCell push-in offset")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* The default theme displaces the contents by one pixel. */
  NSSize offset = [[GSTheme theme] buttonPushInOffsetForCell: nil];
  PASS(offset.width == 1.0 && offset.height == 1.0,
       "the default push-in offset is one pixel to the bottom right");

  NSButtonCell *cell = AUTORELEASE([[NSButtonCell alloc] init]);
  [cell setButtonType: NSMomentaryPushInButton];
  [cell setBordered: YES];
  NSRect bounds = NSMakeRect(0, 0, 120, 32);

  [cell setHighlighted: NO];
  NSRect normal = [cell drawingRectForBounds: bounds];

  [cell setHighlighted: YES];
  NSRect pushed = [cell drawingRectForBounds: bounds];

  /* The contents move by exactly the theme's offset; the view is not flipped,
     so the y axis points up and the downward move is a negative offset. */
  PASS(pushed.origin.x - normal.origin.x == offset.width,
       "a pushed-in cell shifts its contents right by the theme offset");
  PASS(normal.origin.y - pushed.origin.y == offset.height,
       "a pushed-in cell shifts its contents down by the theme offset");
  PASS(NSEqualSizes(pushed.size, normal.size),
       "the push-in offset moves the contents without resizing them");

  END_SET("NSButtonCell push-in offset")

  DESTROY(arp);
  return 0;
}
