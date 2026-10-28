#import "Testing.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "../GSFakeScreens.h"
#import <GNUstepGUI/GSTrackingRect.h>

@interface BackingObserver : NSObject
{
@public
  int count;
  CGFloat oldFactor;
}
@end

@implementation BackingObserver
- (void) changed: (NSNotification *)n
{
  count++;
  oldFactor = [[[n userInfo]
    objectForKey: NSBackingPropertyOldScaleFactorKey] doubleValue];
}
@end

/* A window switches its factor at most once per pass of the run loop,
   so a test that moves it again has to let the pass end first. */
static void
endPass(void)
{
  [[NSRunLoop currentRunLoop] runUntilDate:
    [NSDate dateWithTimeIntervalSinceNow: 0.02]];
}

/* A view with one cursor rect over all of it. */
@interface CursorRectView : NSView
@end

@implementation CursorRectView
- (void) resetCursorRects
{
  [self addCursorRect: [self bounds] cursor: [NSCursor IBeamCursor]];
}
- (NSRect) cursorRectInWindow
{
  GSTrackingRect *r = [[self valueForKey: @"_cursor_rects"] lastObject];

  return r ? [r rectangle] : NSZeroRect;
}
@end

/* A window that lays itself out at a factor of its own choosing. */
@interface FixedFactorWindow : NSWindow
@end

@implementation FixedFactorWindow
- (CGFloat) userSpaceScaleFactor
{
  return 2.0;
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSWindow scale factor of its screen")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      {
        SKIP("It looks like GNUstep backend is not yet installed")
      }
  NS_ENDHANDLER

  {
    NSArray *frames = [NSArray arrayWithObjects:
      [NSValue valueWithRect: NSMakeRect(0, 0, 1000, 800)],
      [NSValue valueWithRect: NSMakeRect(1000, 0, 1000, 800)], nil];
    NSUInteger style = NSTitledWindowMask | NSResizableWindowMask;
    GSFakeScreens *fake;
    NSArray *screens;
    NSWindow *w1;
    NSWindow *w2;
    NSRect content;

    GSSetScaleFactorArgument(nil);
    fake = [GSFakeScreens installWithFrames: frames
      resolutions: [NSArray arrayWithObjects: @"144", @"72", nil]];
    screens = [NSScreen screens];

    w1 = AUTORELEASE([[NSWindow alloc]
      initWithContentRect: NSMakeRect(100, 100, 200, 100)
                styleMask: style
                  backing: NSBackingStoreBuffered
                    defer: YES
                   screen: [screens objectAtIndex: 0]]);
    w2 = AUTORELEASE([[NSWindow alloc]
      initWithContentRect: NSMakeRect(1100, 100, 200, 100)
                styleMask: style
                  backing: NSBackingStoreBuffered
                    defer: YES
                   screen: [screens objectAtIndex: 1]]);

    PASS([w1 userSpaceScaleFactor] == 2.0, "a window on the 144 dpi screen has the factor 2");
    PASS([w2 userSpaceScaleFactor] == 1.0, "a window on the 72 dpi screen has the factor 1");
    PASS(NSEqualSizes([[w1 contentView] frame].size, NSMakeSize(200, 100))
      && NSEqualSizes([[w2 contentView] frame].size, NSMakeSize(200, 100)),
      "both content views have the size they were created with");
    content = [w1 contentRectForFrameRect: [w1 frame]];
    PASS(NSEqualSizes(content.size, NSMakeSize(200, 100)),
      "the content rect of the first window is converted with its factor");
    content = [w2 contentRectForFrameRect: [w2 frame]];
    PASS(NSEqualSizes(content.size, NSMakeSize(200, 100)),
      "the content rect of the second window is converted with its factor");
    PASS(NSWidth([w1 frame]) - NSWidth([w2 frame]) == 200
      && NSHeight([w1 frame]) - NSHeight([w2 frame]) >= 100,
      "the frame on the 144 dpi screen has twice as many pixels of content");
    PASS(NSEqualPoints([w2 frame].origin, NSMakePoint(1100, 100)),
      "a window created for a screen keeps the origin it was given");

    {
      BackingObserver *obs = AUTORELEASE([BackingObserver new]);
      NSRect before;

      [[NSNotificationCenter defaultCenter] addObserver: obs
        selector: @selector(changed:)
        name: NSWindowDidChangeBackingPropertiesNotification
        object: w1];

      [w1 orderFront: nil];
      endPass();
      before = [w1 frame];
      [w1 setFrameOrigin: NSMakePoint(1100, 100)];
      endPass();
      PASS([w1 userSpaceScaleFactor] == 1.0,
        "a window moved to the 72 dpi screen takes its factor");
      PASS(NSEqualSizes([[w1 contentView] frame].size, NSMakeSize(200, 100)),
        "its content view keeps its size in points");
      PASS(NSWidth([w1 frame]) == NSWidth(before) - 200
        && NSHeight([w1 frame]) == NSHeight(before) - 100,
        "its frame loses the pixels of the factor");
      PASS(obs->count == 1 && obs->oldFactor == 2.0,
        "NSWindowDidChangeBackingPropertiesNotification is posted with the old factor");

      [w1 setFrameOrigin: NSMakePoint(100, 100)];

      endPass();
      PASS([w1 userSpaceScaleFactor] == 2.0
        && NSEqualSizes([w1 frame].size, before.size)
        && NSEqualSizes([[w1 contentView] frame].size, NSMakeSize(200, 100)),
        "moving it back restores factor and frame");
      PASS(obs->count == 2 && obs->oldFactor == 1.0,
        "the notification is posted again with the factor of the second screen");

      [w1 setFrameOrigin: NSMakePoint(150, 150)];

      endPass();
      PASS(obs->count == 2 && NSEqualSizes([w1 frame].size, before.size),
        "a move within the screen changes nothing");

      [[NSNotificationCenter defaultCenter] removeObserver: obs];
    }

    {
      NSWindow *w3 = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(300, 300, 200, 100)
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSRect before;

      [w3 orderFront: nil];
      before = [w3 frame];
      [w3 setFrameOrigin: NSMakePoint(1300, 300)];
      endPass();
      PASS([w3 userSpaceScaleFactor] == 1.0
        && NSEqualSizes([[w3 contentView] frame].size, NSMakeSize(200, 100)),
        "a visible window moved to the other screen takes its factor");
      PASS(NSMinX([w3 frame]) == 1300
        && NSMaxY([w3 frame]) == 300 + NSHeight(before),
        "a visible window keeps its top left corner");

      [w3 setFrameOrigin: NSMakePoint(905, 300)];

      endPass();
      PASS([w3 userSpaceScaleFactor] == 1.0,
        "a window mostly on the 72 dpi screen keeps its factor");
      [w3 setFrameOrigin: NSMakePoint(880, 300)];
      endPass();
      PASS([w3 userSpaceScaleFactor] == 2.0
        && NSEqualSizes([[w3 contentView] frame].size, NSMakeSize(200, 100)),
        "it takes the other factor once it would be mostly on that screen at its size there");
      PASS(NSMinX([w3 frame]) == 880,
        "the switch does not move the window");
      [w3 setFrameOrigin: NSMakePoint(881, 300)];
      endPass();
      PASS([w3 userSpaceScaleFactor] == 2.0,
        "a small move back does not switch the factor again");
      [w3 setFrameOrigin: NSMakePoint(920, 300)];
      endPass();
      PASS([w3 userSpaceScaleFactor] == 2.0,
        "nor does a move that would leave it mostly on its screen at the other size");
      [w3 setFrameOrigin: NSMakePoint(1010, 300)];
      endPass();
      PASS([w3 userSpaceScaleFactor] == 1.0,
        "a move past that margin switches it");
      [w3 orderOut: nil];
    }

    {
      NSWindow *desk = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 1000, 400)
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreBuffered
                      defer: YES]);
      CGFloat factor;
      NSRect full = NSMakeRect(0, 0, 2000, 800);

      [desk setLevel: NSDesktopWindowLevel];
      [desk setFrame: full display: NO];
      factor = [desk userSpaceScaleFactor];
      [desk orderFront: nil];
      PASS([desk userSpaceScaleFactor] == factor
        && NSEqualRects([desk frame], full),
        "a desktop window spanning both screens keeps factor and frame when shown");
      [desk setFrame: NSMakeRect(500, 0, 1500, 800) display: NO];
      PASS([desk userSpaceScaleFactor] == factor
        && NSEqualRects([desk frame], NSMakeRect(500, 0, 1500, 800)),
        "a desktop window mostly on the other screen keeps its factor and the frame it was given");
      [desk setFrame: full display: NO];
      PASS([desk userSpaceScaleFactor] == factor
        && NSEqualRects([desk frame], full),
        "and covers both screens again with the frame it is given");
      [desk orderOut: nil];
    }

    {
      /* Hidden, straddling the edge: it has nothing on the screen to judge
         by, so it keeps its factor until it is ordered in. */
      NSWindow *hidden = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(900, 300, 200, 100)
                  styleMask: style
                    backing: NSBackingStoreBuffered
                      defer: YES
                     screen: [screens objectAtIndex: 0]]);
      CGFloat factor = [hidden userSpaceScaleFactor];
      NSSize size = [hidden frame].size;
      int i;

      for (i = 0; i < 5; i++)
        {
          [hidden setFrameOrigin: NSMakePoint(i % 2 ? 700 : 900, 300)];
          endPass();
        }
      PASS([hidden userSpaceScaleFactor] == factor
        && NSEqualSizes([hidden frame].size, size),
        "a hidden window moved over the edge keeps its factor and size");
      [hidden setFrameOrigin: NSMakePoint(1300, 300)];
      [hidden orderFront: nil];
      PASS([hidden userSpaceScaleFactor] == 1.0
        && NSEqualSizes([[hidden contentView] frame].size, NSMakeSize(200, 100)),
        "it takes the factor of its screen when it is ordered in");
      [hidden orderOut: nil];
    }

    {
      BackingObserver *obs = AUTORELEASE([BackingObserver new]);
      NSWindow *w5 = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(300, 300, 200, 100)
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      int i;

      [w5 orderFront: nil];
      endPass();
      [[NSNotificationCenter defaultCenter] addObserver: obs
        selector: @selector(changed:)
        name: NSWindowDidChangeBackingPropertiesNotification
        object: w5];
      [w5 setFrameOrigin: NSMakePoint(1300, 300)];
      [w5 setFrameOrigin: NSMakePoint(300, 300)];
      PASS(obs->count == 1 && [w5 userSpaceScaleFactor] == 1.0,
        "a window switches its factor at most once per pass of the run loop");
      endPass();
      [w5 setFrameOrigin: NSMakePoint(310, 300)];
      PASS(obs->count == 2 && [w5 userSpaceScaleFactor] == 2.0,
        "in the next pass it may switch again");
      endPass();
      for (i = 0; i < 10; i++)
        {
          [w5 setFrameOrigin: NSMakePoint(i % 2 ? 300 : 1300, 300)];
          endPass();
        }
      PASS(obs->count == 6,
        "a window flipping back and forth stops after six switches in two seconds");
      [[NSNotificationCenter defaultCenter] removeObserver: obs];
      [w5 orderOut: nil];
    }

    {
      /* Cursor rects are kept in window coordinates, device pixels: they
         must cover the view's pixels at the window's factor. */
      NSWindow *cw = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(100, 300, 200, 100)
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO
                     screen: [screens objectAtIndex: 0]]);
      CursorRectView *cv = AUTORELEASE([[CursorRectView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);
      NSRect pixels;

      [cw setContentView: cv];
      [cw orderFront: nil];
      endPass();
      [cw resetCursorRects];
      pixels = [cv convertRect: [cv bounds] toView: nil];
      PASS(NSEqualRects([cv cursorRectInWindow], pixels)
        && NSWidth(pixels) == 200 * [cw userSpaceScaleFactor],
        "a cursor rect covers the view's device pixels on a 2.0 screen");
      [cw setFrameOrigin: NSMakePoint(1300, 300)];
      endPass();
      [cw resetCursorRects];
      pixels = [cv convertRect: [cv bounds] toView: nil];
      PASS([cw userSpaceScaleFactor] == 1.0
        && NSEqualRects([cv cursorRectInWindow], pixels)
        && NSWidth(pixels) == 200,
        "rebuilt after the window took another factor, they cover its pixels at that factor");
      [cw orderOut: nil];
    }

    [fake uninstall];

    fake = [GSFakeScreens installWithFrames: frames
      resolutions: [NSArray arrayWithObjects: @"72", @"72", nil]];
    {
      BackingObserver *obs = AUTORELEASE([BackingObserver new]);
      NSWindow *w4 = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(100, 100, 200, 100)
                  styleMask: style
                  backing: NSBackingStoreBuffered
                    defer: YES]);
      NSRect before = [w4 frame];

      [[NSNotificationCenter defaultCenter] addObserver: obs
        selector: @selector(changed:)
        name: NSWindowDidChangeBackingPropertiesNotification
        object: w4];
      [w4 setFrameOrigin: NSMakePoint(1100, 100)];
      PASS(obs->count == 0 && NSEqualSizes([w4 frame].size, before.size),
        "with one factor for all screens a move changes nothing");
      [[NSNotificationCenter defaultCenter] removeObserver: obs];
    }
    {
      /* Laid out at the factor of two 72 dpi screens (GSScaleFactor if
         set), then the screens become 216 and 144 dpi: no screen has the
         window's factor any more, which makes an ordinary window take the
         new one at its next move. */
      CGFloat factor;
      NSWindow *desk = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 2000, 800)
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreBuffered
                      defer: YES]);
      NSRect full = NSMakeRect(0, 0, 2000, 800);

      [desk setLevel: NSDesktopWindowLevel];
      [desk setFrame: full display: NO];
      [desk orderFront: nil];
      factor = [desk userSpaceScaleFactor];
      [fake uninstall];
      fake = [GSFakeScreens installWithFrames: frames
        resolutions: [NSArray arrayWithObjects: @"216", @"144", nil]];
      [desk setFrame: NSMakeRect(0, 1, 2000, 800) display: NO];
      [desk setFrame: full display: NO];
      PASS([desk userSpaceScaleFactor] == factor
        && NSEqualRects([desk frame], full)
        && NSEqualSizes([[desk contentView] frame].size,
          NSMakeSize(NSWidth(full) / factor, NSHeight(full) / factor)),
        "a desktop window keeps its factor and frame when the screens change theirs");
      [desk orderOut: nil];
    }
    {
      /* The decoration view must convert the frame with the factor the
         window reports, or a subclass that overrides it gets bounds of
         one factor and a content view sized with another. */
      NSWindow *fixed = AUTORELEASE([[FixedFactorWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 100)
                  styleMask: NSBorderlessWindowMask
                    backing: NSBackingStoreBuffered
                      defer: YES]);

      NSSize frameSize;

      [fixed setFrame: NSMakeRect(0, 0, 400, 200) display: NO];
      frameSize = [fixed frame].size;
      PASS(NSEqualSizes([[fixed contentView] frame].size,
          NSMakeSize(frameSize.width / 2, frameSize.height / 2)),
        "a window overriding -userSpaceScaleFactor gets a content view of its frame at that factor");
    }
    [fake uninstall];
  }

  END_SET("NSWindow scale factor of its screen")

  DESTROY(arp);
  return 0;
}
