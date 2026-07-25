/* The background of a menu view can be rounded by the theme through
   -[GSTheme menuBorderRadius] (gnustep/libs-gui#223).  The default is zero,
   which fills the whole menu rectangle; a larger radius fills the background
   through a rounded rectangle, leaving the corners to the (clear, borderless)
   menu window.  This draws the menu background on a white background and reads
   back a corner pixel, so it needs the backend and the body is guarded. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <GNUstepGUI/GSTheme.h>

/* Both themes paint the menu background red so the fill is visible; they
   differ only in the corner radius. */
@interface FlatMenuTheme : GSTheme
@end
@implementation FlatMenuTheme
- (NSString *) name
{
  return @"FlatMenuTheme";
}
- (NSColor *) menuBackgroundColor
{
  return [NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0];
}
- (CGFloat) menuBorderRadius
{
  return 0.0;
}
@end

@interface RoundMenuTheme : FlatMenuTheme
@end
@implementation RoundMenuTheme
- (NSString *) name
{
  return @"RoundMenuTheme";
}
- (CGFloat) menuBorderRadius
{
  return 12.0;
}
@end

/* Draw the menu background filling the view and return the colour at (x, y) in
   calibrated RGB. */
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
  NSBitmapImageRep *rep;
  NSColor *c;

  [w setContentView: v];
  [v lockFocus];
  [[NSColor whiteColor] set];
  NSRectFill(NSMakeRect(0, 0, side, side));

  [[GSTheme theme] drawBackgroundForMenuView: nil
    withFrame: NSMakeRect(0, 0, side, side)
    dirtyRect: NSMakeRect(0, 0, side, side)
    horizontal: NO];

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

static BOOL
isWhite(NSColor *c)
{
  return [c redComponent] > 0.7 && [c greenComponent] > 0.7
    && [c blueComponent] > 0.7;
}

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenuView border radius")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* The default theme does not round the menu background. */
  PASS([[GSTheme theme] menuBorderRadius] == 0.0,
       "the default menu border radius is zero");

  GSTheme *saved = RETAIN([GSTheme theme]);

  /* A zero radius fills the whole rectangle, so a corner is painted. */
  [GSTheme setTheme: AUTORELEASE([[FlatMenuTheme alloc] initWithBundle: nil])];
  NSColor *flatCorner = drawnPixel(40, 1, 1);

  /* A non-zero radius rounds the corners, so the corner keeps the white
     background while the centre is still painted. */
  [GSTheme setTheme: AUTORELEASE([[RoundMenuTheme alloc] initWithBundle: nil])];
  NSColor *roundCentre = drawnPixel(40, 20, 20);
  NSColor *roundCorner = drawnPixel(40, 1, 1);

  [GSTheme setTheme: saved];
  RELEASE(saved);

  PASS(isRed(flatCorner),
       "a zero radius fills the menu corner");
  PASS(isRed(roundCentre),
       "a non-zero radius still fills the menu centre");
  PASS(isWhite(roundCorner),
       "a non-zero radius leaves the menu corner unfilled");

  END_SET("NSMenuView border radius")

  DESTROY(arp);
  return 0;
}
