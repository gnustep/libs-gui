/* A theme can inset the item cells of a vertical menu within the menu's edges
   through -[GSTheme menuItemAreaInsets] (gnustep/libs-gui#220).  The default is
   zero on every side; with non-zero insets -[NSMenuView sizeToFit] grows the
   frame and -[NSMenuView rectOfItemAtIndex:] moves the cells by the same
   amount, and hit testing follows.  Laying out a menu needs the backend, so the
   body is guarded. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuView.h>
#import <GNUstepGUI/GSTheme.h>

@interface PadTheme : GSTheme
@end

@implementation PadTheme
- (NSString *) name
{
  return @"PadTheme";
}
- (NSEdgeInsets) menuItemAreaInsets
{
  return NSEdgeInsetsMake(7.0, 11.0, 3.0, 13.0);
}
@end

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenuView item area insets")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* The default theme insets nothing. */
  NSEdgeInsets d = [[GSTheme theme] menuItemAreaInsets];
  PASS(d.top == 0.0 && d.left == 0.0 && d.bottom == 0.0 && d.right == 0.0,
       "the default menu item area insets are zero");

  NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"M"]);
  [menu addItemWithTitle: @"One" action: NULL keyEquivalent: @""];
  [menu addItemWithTitle: @"Two" action: NULL keyEquivalent: @""];
  [menu addItemWithTitle: @"Three" action: NULL keyEquivalent: @""];
  NSMenuView *mv = [menu menuRepresentation];

  [mv setNeedsSizing: YES];
  [mv sizeToFit];
  NSRect plainFrame = [mv frame];
  NSRect plainItem = [mv rectOfItemAtIndex: 1];

  /* Install a theme that insets the item area and measure again. */
  GSTheme *saved = RETAIN([GSTheme theme]);
  [GSTheme setTheme: AUTORELEASE([[PadTheme alloc] initWithBundle: nil])];
  [mv setNeedsSizing: YES];
  [mv sizeToFit];
  NSRect padFrame = [mv frame];
  NSRect padItem = [mv rectOfItemAtIndex: 1];
  NSInteger hit = [mv indexOfItemAtPoint:
    NSMakePoint(NSMidX(padItem), NSMidY(padItem))];
  [GSTheme setTheme: saved];
  RELEASE(saved);

  PASS(padFrame.size.width - plainFrame.size.width == 11.0 + 13.0,
       "insets widen the menu by the left and right insets");
  PASS(padFrame.size.height - plainFrame.size.height == 7.0 + 3.0,
       "insets heighten the menu by the top and bottom insets");
  PASS(padItem.origin.x - plainItem.origin.x == 11.0,
       "an item moves right by the left inset");
  PASS(padItem.origin.y - plainItem.origin.y == 3.0,
       "an item moves up by the bottom inset");
  PASS(NSEqualSizes(padItem.size, plainItem.size),
       "insetting the item area does not resize the cells");
  PASS(hit == 1,
       "hit testing still finds the item under its inset rect");

  END_SET("NSMenuView item area insets")

  DESTROY(arp);
  return 0;
}
