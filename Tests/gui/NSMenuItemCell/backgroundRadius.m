/* The background of a highlighted menu item can be rounded by the theme through
   -[GSTheme menuItemBackgroundRadius] (gnustep/libs-gui#221).  The default is
   zero, which fills the whole item rectangle; a larger radius rounds the
   corners of the highlight, leaving the menu background showing through them.
   This draws a highlighted item on a white background and reads back a corner
   pixel, so it needs the backend and the body is guarded. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSMenuItemCell.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <GNUstepGUI/GSTheme.h>

/* Both themes paint the selected item red so the fill is visible; they differ
   only in the corner radius. */
@interface FlatRedTheme : GSTheme
@end
@implementation FlatRedTheme
- (NSString *) name
{
  return @"FlatRedTheme";
}
- (NSColor *) colorNamed: (NSString *)aName state: (GSThemeControlState)state
{
  if ([aName isEqualToString: @"NSMenuItem"])
    return [NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0];
  return [super colorNamed: aName state: state];
}
- (CGFloat) menuItemBackgroundRadius
{
  return 0.0;
}
@end

@interface RoundRedTheme : FlatRedTheme
@end
@implementation RoundRedTheme
- (NSString *) name
{
  return @"RoundRedTheme";
}
- (CGFloat) menuItemBackgroundRadius
{
  return 12.0;
}
@end

/* Draw a highlighted menu item filling the view and return the colour at (x, y)
   in calibrated RGB. */
static NSColor *
drawnPixel(int side, int x, int y)
{
  NSWindow *w = AUTORELEASE([[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, side, side)
              styleMask: NSWindowStyleMaskBorderless
                backing: NSBackingStoreBuffered
                  defer: NO]);
  NSView *v = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, side, side)]);
  NSMenuItemCell *cell = AUTORELEASE([[NSMenuItemCell alloc] init]);
  NSBitmapImageRep *rep;
  NSColor *c;

  [w setContentView: v];
  [v lockFocus];
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, side, side));

  [cell setBordered: NO];
  [cell setHighlightsBy: NSPushInCellMask];
  [cell setHighlighted: YES];
  [[GSTheme theme] drawBorderAndBackgroundForMenuItemCell: cell
    withFrame: NSMakeRect(0, 0, side, side)
    inView: v
    state: GSThemeSelectedState
    isHorizontal: NO];

  rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithFocusedViewRect: NSMakeRect(0, 0, side, side)]);
  [v unlockFocus];
  c = [rep colorAtX: x y: y];
  return [c colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
}

static BOOL
isRed(NSColor *c)
{
  return [c redComponent] > 0.7 && [c greenComponent] < 0.3
    && [c blueComponent] < 0.3;
}

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenuItemCell background radius")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* The default theme does not round the highlight. */
  PASS([[GSTheme theme] menuItemBackgroundRadius] == 0.0,
       "the default menu item background radius is zero");

  GSTheme *saved = RETAIN([GSTheme theme]);

  /* A zero radius fills the whole rectangle, so a corner is painted. */
  [GSTheme setTheme: AUTORELEASE([[FlatRedTheme alloc] initWithBundle: nil])];
  NSColor *flatCenter = drawnPixel(40, 20, 20);
  NSColor *flatCorner = drawnPixel(40, 1, 1);

  /* A non-zero radius rounds the corners, so the corner keeps the white
     background while the centre is still painted. */
  [GSTheme setTheme: AUTORELEASE([[RoundRedTheme alloc] initWithBundle: nil])];
  NSColor *roundCenter = drawnPixel(40, 20, 20);
  NSColor *roundCorner = drawnPixel(40, 1, 1);

  [GSTheme setTheme: saved];
  RELEASE(saved);

  PASS(isRed(flatCenter), "a highlighted item is painted at its centre");
  PASS(isRed(flatCorner),
       "with a zero radius the highlight reaches the corner");
  PASS(isRed(roundCenter),
       "a rounded highlight is still painted at its centre");
  PASS(!isRed(roundCorner),
       "with a non-zero radius the highlight does not reach the corner");

  END_SET("NSMenuItemCell background radius")

  DESTROY(arp);
  return 0;
}
