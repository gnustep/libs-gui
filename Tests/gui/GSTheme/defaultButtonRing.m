/* A theme may mark the default button with a ring outside the button's
 * frame.  When the theme reports a ring outset, the default button does not
 * want the default clipping, so the ring the theme draws with the button
 * shows, and the ring area is redrawn whenever the ring would go stale.
 *
 * RingTheme draws a frame of RING_WIDTH points RING_OUTSET points around
 * the default button: red in a key window when the button is enabled,
 * green otherwise.  The pixels are read back from the window, so the test
 * needs a display.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <GNUstepGUI/GSTheme.h>

#define RING_OUTSET 4.0
#define RING_WIDTH 3.0

@interface RingTheme : GSTheme
{
@public
  CGFloat	outset;
}
@end

@implementation RingTheme
- (CGFloat) defaultButtonRingOutset
{
  return outset;
}

- (void) drawButton: (NSRect)frame
                 in: (NSCell *)cell
               view: (NSView *)view
              style: (int)style
              state: (GSThemeControlState)state
{
  NSRect	f;

  [super drawButton: frame in: cell view: view style: style state: state];
  if (outset <= 0.0 || [[view window] defaultButtonCell] != cell)
    {
      return;
    }
  if ([cell isEnabled] && [[view window] isKeyWindow])
    {
      [[NSColor redColor] set];
    }
  else
    {
      [[NSColor greenColor] set];
    }
  f = NSInsetRect([view bounds], -outset, -outset);
  NSRectFill(NSMakeRect(NSMinX(f), NSMinY(f), NSWidth(f), RING_WIDTH));
  NSRectFill(NSMakeRect(NSMinX(f), NSMaxY(f) - RING_WIDTH,
    NSWidth(f), RING_WIDTH));
  NSRectFill(NSMakeRect(NSMinX(f), NSMinY(f), RING_WIDTH, NSHeight(f)));
  NSRectFill(NSMakeRect(NSMaxX(f) - RING_WIDTH, NSMinY(f),
    RING_WIDTH, NSHeight(f)));
}
@end

@interface WhiteView : NSView
@end

@implementation WhiteView
- (void) drawRect: (NSRect)r
{
  [[NSColor whiteColor] set];
  NSRectFill(r);
}
@end

static RingTheme	*theme;
static NSWindow		*window;
static WhiteView	*content;

static NSColor *
pixel(NSView *view, CGFloat x, CGFloat y)
{
  NSBitmapImageRep	*rep;
  NSColor		*c;

  [view lockFocus];
  rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:
    NSMakeRect(x, y, 1, 1)];
  [view unlockFocus];
  c = [[rep colorAtX: 0 y: 0]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  [rep release];
  return c;
}

static BOOL
isRed(NSView *view, CGFloat x, CGFloat y)
{
  NSColor	*c = pixel(view, x, y);

  return [c redComponent] > 0.9 && [c greenComponent] < 0.1;
}

static BOOL
isGreen(NSView *view, CGFloat x, CGFloat y)
{
  NSColor	*c = pixel(view, x, y);

  return [c greenComponent] > 0.9 && [c redComponent] < 0.1;
}

static BOOL
isWhite(NSView *view, CGFloat x, CGFloat y)
{
  NSColor	*c = pixel(view, x, y);

  return [c redComponent] > 0.9 && [c greenComponent] > 0.9
    && [c blueComponent] > 0.9;
}

static NSButton *
makeButton(NSRect frame)
{
  NSButton	*b = [[[NSButton alloc] initWithFrame: frame] autorelease];

  [b setTitle: @"OK"];
  [content addSubview: b];
  return b;
}

static void
reset(void)
{
  [window setDefaultButtonCell: nil];
  [[[[content subviews] copy] autorelease]
    makeObjectsPerformSelector: @selector(removeFromSuperview)];
  theme->outset = RING_OUTSET;
  [window display];
}

int
main(int argc, char **argv)
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];
  NSButton		*a;
  NSButton		*b;

  START_SET("default button ring")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name]
	isEqualToString: NSInternalInconsistencyException])
	{
	  SKIP("It looks like GNUstep backend is not yet installed")
	}
    }
  NS_ENDHANDLER

  theme = [[RingTheme alloc] initWithBundle: nil];
  [GSTheme setTheme: theme];

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(50, 50, 300, 200)
				       styleMask: NSBorderlessWindowMask
					 backing: NSBackingStoreBuffered
					   defer: NO];
  content = [[WhiteView alloc] initWithFrame: NSMakeRect(0, 0, 300, 200)];
  [window setContentView: content];
  [window orderFrontRegardless];
  [window becomeKeyWindow];

  /* Button a covers 40..120 x 40..70, its ring 36..124 x 36..74. */
  reset();
  a = makeButton(NSMakeRect(40, 40, 80, 30));
  b = makeButton(NSMakeRect(160, 40, 80, 30));
  [window display];
  PASS([a wantsDefaultClipping], "a button wants the default clipping");
  PASS(isWhite(content, 37, 37), "no ring without a default button");

  [window setDefaultButtonCell: [a cell]];
  [window displayIfNeeded];
  PASS(![a wantsDefaultClipping] && [b wantsDefaultClipping],
    "the default button does not want the default clipping");
  PASS(isRed(content, 37, 37) && isRed(content, 123, 72),
    "the ring is drawn outside the button");

  [content setNeedsDisplayInRect: NSMakeRect(36, 50, 3, 3)];
  [window displayIfNeeded];
  PASS(isRed(content, 37, 51), "a redraw of the superview keeps the ring");

  [window setDefaultButtonCell: [b cell]];
  [window displayIfNeeded];
  PASS(isWhite(content, 37, 37), "the old default button loses its ring");
  PASS(isRed(content, 157, 37), "the new default button gets one");

  [window setDefaultButtonCell: [a cell]];
  [window displayIfNeeded];
  [a setFrameOrigin: NSMakePoint(50, 100)];
  [window displayIfNeeded];
  PASS(isWhite(content, 37, 37), "no stale ring after moving");
  PASS(isRed(content, 47, 97), "the ring follows the button");
  [a setFrameOrigin: NSMakePoint(40, 40)];
  [window displayIfNeeded];

  [a setEnabled: NO];
  [window displayIfNeeded];
  PASS(isGreen(content, 37, 37), "disabling redraws the ring");
  [a setEnabled: YES];
  [window displayIfNeeded];
  PASS(isRed(content, 37, 37), "enabling redraws the ring");

  [window resignKeyWindow];
  [window displayIfNeeded];
  PASS(isGreen(content, 37, 37), "the window losing key redraws the ring");
  [window becomeKeyWindow];
  [window displayIfNeeded];
  PASS(isRed(content, 37, 37), "the window becoming key redraws the ring");

  [a setHidden: YES];
  [window displayIfNeeded];
  PASS(isWhite(content, 37, 37), "no ring left after hiding");
  [a setHidden: NO];
  [window displayIfNeeded];
  PASS(isRed(content, 37, 37), "the ring comes back with the button");

  [[a retain] autorelease];
  [a removeFromSuperview];
  [window displayIfNeeded];
  PASS(isWhite(content, 37, 37), "no ring left after removal");
  [content addSubview: a];
  [window displayIfNeeded];
  PASS(isRed(content, 37, 37), "the ring comes back when it is added");

  /* A theme without a ring changes nothing */
  reset();
  theme->outset = 0.0;
  a = makeButton(NSMakeRect(40, 40, 80, 30));
  [window setDefaultButtonCell: [a cell]];
  [window display];
  PASS([a wantsDefaultClipping], "without a ring the clipping stays");
  PASS(isWhite(content, 37, 37), "and nothing is drawn outside");

  /* A superview that is smaller than the ring cuts it off */
  {
    WhiteView	*tight;

    reset();
    tight = [[[WhiteView alloc] initWithFrame:
      NSMakeRect(100, 100, 84, 34)] autorelease];
    [content addSubview: tight];
    a = [[[NSButton alloc] initWithFrame: NSMakeRect(2, 2, 80, 30)]
      autorelease];
    [tight addSubview: a];
    [window setDefaultButtonCell: [a cell]];
    [window display];
    PASS(isRed(tight, 0, 0), "the ring is drawn inside the superview");
    PASS(isWhite(content, 98, 98), "but not outside of it");
  }

  /* Inside a box */
  {
    NSBox	*box;

    reset();
    box = [[[NSBox alloc] initWithFrame: NSMakeRect(10, 10, 280, 180)]
      autorelease];
    [box setTitlePosition: NSNoTitle];
    [content addSubview: box];
    a = [[[NSButton alloc] initWithFrame: NSMakeRect(40, 40, 80, 30)]
      autorelease];
    [[box contentView] addSubview: a];
    [window setDefaultButtonCell: [a cell]];
    [window display];
    PASS(isRed([box contentView], 37, 37), "the ring is drawn in a box");
  }

  /* The window keeps the cell of a button that is gone */
  {
    NSButton		*gone;
    NSButtonCell	*cell;

    reset();
    gone = [[NSButton alloc] initWithFrame: NSMakeRect(40, 40, 80, 30)];
    cell = [gone cell];
    [content addSubview: gone];
    [window setDefaultButtonCell: cell];
    [window display];
    [gone removeFromSuperview];
    [gone release];
    PASS([cell controlView] == nil,
      "a cell does not outlive its control view");
    PASS_RUNS([window resignKeyWindow]; [window becomeKeyWindow];
      [window display], "the window still draws");
    [window setDefaultButtonCell: nil];
  }

  /* Alert panels have a default button like every other panel */
  {
    NSPanel	*alert = NSGetAlertPanel(@"Title", @"Message", @"Yes", @"No", nil);

    PASS([[alert defaultButtonCell] isKindOfClass: [NSButtonCell class]]
      && [[[alert defaultButtonCell] title] isEqual: @"Yes"],
      "the first button of an alert panel is its default button");
    NSReleaseAlertPanel(alert);
  }

  [window orderOut: nil];
  END_SET("default button ring")

  [pool release];
  return 0;
}
