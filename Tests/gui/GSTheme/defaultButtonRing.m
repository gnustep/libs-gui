/* A theme may mark the default button with a ring outside the button's frame.
 * A view is clipped to its own bounds, so the ring has to be painted in the
 * superview, after the subviews, and the superview has to redraw the ring area
 * whenever the ring would otherwise go stale.
 *
 * RingTheme paints a solid red frame of three points around the button and
 * reports an outset of RING_OUTSET points.  The pixels are read back from the
 * window, so the test needs a display and runs on any.
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
  unsigned	draws;
  NSCell	*lastCell;
  NSView	*lastView;
  NSView	*lastFocus;
}
@end

@implementation RingTheme
- (CGFloat) defaultButtonRingOutset
{
  return outset;
}
- (void) drawDefaultButtonRingForCell: (NSButtonCell *)cell
                               inView: (NSView *)view
{
  NSRect	f;

  draws++;
  lastCell = cell;
  lastView = view;
  lastFocus = [NSView focusView];
  f = [view convertRect: [[cell controlView] bounds]
               fromView: [cell controlView]];
  f = NSInsetRect(f, -outset, -outset);
  [[NSColor redColor] set];
  NSRectFill(NSMakeRect(NSMinX(f), NSMinY(f), NSWidth(f), RING_WIDTH));
  NSRectFill(NSMakeRect(NSMinX(f), NSMaxY(f) - RING_WIDTH,
    NSWidth(f), RING_WIDTH));
  NSRectFill(NSMakeRect(NSMinX(f), NSMinY(f), RING_WIDTH, NSHeight(f)));
  NSRectFill(NSMakeRect(NSMaxX(f) - RING_WIDTH, NSMinY(f),
    RING_WIDTH, NSHeight(f)));
}
@end

/* White, not opaque, and it remembers what it was told to redraw. */
@interface PlainView : NSView
{
@public
  NSMutableArray	*dirty;
}
@end

@implementation PlainView
- (void) drawRect: (NSRect)r
{
  [[NSColor whiteColor] set];
  NSRectFill(r);
}
- (void) setNeedsDisplayInRect: (NSRect)r
{
  [dirty addObject: [NSValue valueWithRect: r]];
  [super setNeedsDisplayInRect: r];
}
@end

@interface OpaqueView : PlainView
@end

@implementation OpaqueView
- (BOOL) isOpaque
{
  return YES;
}
@end

static RingTheme	*theme;
static NSWindow		*window;
static PlainView	*content;

static BOOL
dirtied(PlainView *v, NSRect want)
{
  NSEnumerator	*e = [v->dirty objectEnumerator];
  NSValue	*n;

  while ((n = [e nextObject]) != nil)
    {
      if (NSContainsRect([n rectValue], want))
	{
	  return YES;
	}
    }
  return NO;
}

static NSRect
ringOf(NSView *button)
{
  return NSInsetRect([button frame], -RING_OUTSET, -RING_OUTSET);
}

static BOOL
isRed(NSView *view, CGFloat x, CGFloat y)
{
  NSBitmapImageRep	*rep;
  NSColor		*c;

  [view lockFocus];
  rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:
    NSMakeRect(x, y, 1, 1)];
  [view unlockFocus];
  c = [[rep colorAtX: 0 y: 0]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  [rep autorelease];
  return [c redComponent] > 0.9 && [c greenComponent] < 0.1;
}

static NSButton *
makeButton(NSRect frame)
{
  NSButton	*b = [[[NSButton alloc] initWithFrame: frame] autorelease];

  [b setTitle: @"OK"];
  return b;
}

static void
settle(void)
{
  [window display];
  theme->draws = 0;
  [content->dirty removeAllObjects];
}

static void
reset(void)
{
  [window setDefaultButtonCell: nil];
  [[[[content subviews] copy] autorelease]
    makeObjectsPerformSelector: @selector(removeFromSuperview)];
  theme->outset = RING_OUTSET;
  settle();
}

int
main(int argc, char **argv)
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];
  NSButton		*a;
  NSButton		*b;
  NSRect		oldRing;

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
  theme->outset = RING_OUTSET;

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(50, 50, 300, 200)
				       styleMask: NSBorderlessWindowMask
					 backing: NSBackingStoreBuffered
					   defer: NO];
  content = [[PlainView alloc] initWithFrame: NSMakeRect(0, 0, 300, 200)];
  content->dirty = [NSMutableArray new];
  [window setContentView: content];
  [window orderFrontRegardless];

  /* The call */
  a = makeButton(NSMakeRect(40, 40, 80, 30));
  b = makeButton(NSMakeRect(160, 40, 80, 30));
  [content addSubview: a];
  [content addSubview: b];
  settle();
  PASS(theme->draws == 0, "no default button, no call");

  [window setDefaultButtonCell: [a cell]];
  settle();
  [content setNeedsDisplay: YES];
  [window displayIfNeeded];
  PASS(theme->draws == 1, "one call per display of the superview");
  PASS(theme->lastCell == [a cell], "the theme gets the default cell");
  PASS(theme->lastView == content, "the theme gets the superview");
  PASS(theme->lastFocus == content, "the superview has the focus");
  PASS(isRed(content, 37, 37), "the ring is painted outside the button");
  PASS(isRed(content, 123, 72), "on all of its sides");

  theme->draws = 0;
  [a setHidden: YES];
  [content display];
  PASS(theme->draws == 0, "no ring for a hidden button");
  [a setHidden: NO];

  /* The default implementation changes nothing */
  reset();
  theme->outset = 0;
  [content addSubview: a];
  [content addSubview: b];
  settle();
  [window setDefaultButtonCell: [a cell]];
  [a setFrameOrigin: NSMakePoint(30, 30)];
  [a setEnabled: NO];
  [a setEnabled: YES];
  [window becomeKeyWindow];
  [window resignKeyWindow];
  PASS([content->dirty count] == 0,
    "an outset of 0 causes no invalidation at all");
  [content display];
  PASS(theme->draws == 0, "an outset of 0 causes no call");

  /* Invalidation */
  reset();
  [content addSubview: a];
  [content addSubview: b];
  [window setDefaultButtonCell: [a cell]];
  settle();

  [window setDefaultButtonCell: [b cell]];
  PASS(dirtied(content, ringOf(a)), "the old default button's ring area");
  PASS(dirtied(content, ringOf(b)), "the new default button's ring area");
  [content display];
  PASS(!isRed(content, 37, 37), "the old ring is gone");
  PASS(isRed(content, 157, 37), "the new ring is there");

  [window setDefaultButtonCell: [a cell]];
  settle();
  oldRing = ringOf(a);
  [a setFrameOrigin: NSMakePoint(50, 60)];
  PASS(dirtied(content, oldRing) && dirtied(content, ringOf(a)),
    "moving: both ring areas");
  [content->dirty removeAllObjects];
  oldRing = ringOf(a);
  [a setFrameSize: NSMakeSize(70, 40)];
  PASS(dirtied(content, oldRing) && dirtied(content, ringOf(a)),
    "resizing: both ring areas");
  [content->dirty removeAllObjects];
  oldRing = ringOf(a);
  [a setFrame: NSMakeRect(40, 40, 80, 30)];
  PASS(dirtied(content, oldRing) && dirtied(content, ringOf(a)),
    "-setFrame: both ring areas");
  [window displayIfNeeded];
  PASS(!isRed(content, 47, 107), "no stale ring after moving");
  PASS(isRed(content, 37, 37), "the ring follows the button");

  settle();
  [a setHidden: YES];
  PASS(dirtied(content, ringOf(a)), "hiding");
  [window displayIfNeeded];
  PASS(!isRed(content, 37, 37), "no ring left after hiding");
  [content->dirty removeAllObjects];
  [a setHidden: NO];
  PASS(dirtied(content, ringOf(a)), "showing");
  [window displayIfNeeded];
  PASS(isRed(content, 37, 37), "the ring comes back");

  settle();
  [a setEnabled: NO];
  PASS(dirtied(content, ringOf(a)), "disabling");
  [content->dirty removeAllObjects];
  [a setEnabled: YES];
  PASS(dirtied(content, ringOf(a)), "enabling");

  settle();
  [window becomeKeyWindow];
  PASS(dirtied(content, ringOf(a)), "the window becoming key");
  [content->dirty removeAllObjects];
  [window resignKeyWindow];
  PASS(dirtied(content, ringOf(a)), "the window losing key");

  settle();
  [[a retain] autorelease];
  [a removeFromSuperview];
  PASS(dirtied(content, ringOf(a)), "removal from the superview");
  [window displayIfNeeded];
  PASS(!isRed(content, 37, 37), "no ring left after removal");
  [content->dirty removeAllObjects];
  [content addSubview: a];
  PASS(dirtied(content, ringOf(a)), "adding it back");
  [window displayIfNeeded];
  PASS(isRed(content, 37, 37), "the ring comes back with the button");

  /* Partial redraws */
  settle();
  [content displayRect: NSMakeRect(200, 150, 20, 20)];
  PASS(theme->draws == 0, "a redraw away from the ring does not call");
  [content displayRect: NSMakeRect(30, 30, 5, 5)];
  PASS(theme->draws == 0, "nor does one that just misses it");
  [content displayRect: NSMakeRect(36, 36, 3, 3)];
  PASS(theme->draws == 1, "one that touches it does");
  PASS(isRed(content, 37, 37), "and the exposed part comes back");

  {
    OpaqueView	*neighbor;
    NSBox	*box;
    OpaqueView	*deep;

    reset();
    [content addSubview: a];
    neighbor = [[[OpaqueView alloc] initWithFrame:
      NSMakeRect(115, 30, 40, 50)] autorelease];
    neighbor->dirty = [NSMutableArray new];
    [content addSubview: neighbor];
    [window setDefaultButtonCell: [a cell]];
    settle();
    PASS(isRed(content, 123, 55), "the ring lies over the neighbor");
    [neighbor display];
    PASS(isRed(content, 123, 55), "a neighbor displaying itself keeps it");
    PASS(theme->draws == 1, "painted once for that");
    theme->draws = 0;
    [neighbor setNeedsDisplay: YES];
    [window displayIfNeeded];
    PASS(isRed(content, 123, 55), "a neighbor redrawn from the window keeps it");
    PASS(theme->draws == 1, "painted once for that too");
    theme->draws = 0;
    [content display];
    PASS(theme->draws == 1, "the superview does not paint it twice");

    [neighbor removeFromSuperview];
    box = [[[NSBox alloc] initWithFrame:
      NSMakeRect(115, 20, 60, 70)] autorelease];
    [box setTitlePosition: NSNoTitle];
    deep = [[[OpaqueView alloc] initWithFrame:
      NSMakeRect(0, 0, 40, 60)] autorelease];
    deep->dirty = [NSMutableArray new];
    [box setContentView: deep];
    [content addSubview: box];
    settle();
    [deep display];
    theme->draws = 0;
    [deep display];
    PASS(theme->draws == 1, "a view deeper down repaints it, once");
  }

  {
    PlainView	*tight;
    PlainView	*outer;

    /* The superview cuts the ring off.  Inside it there is ring, and the
     * parent of the superview stays clean. */
    reset();
    tight = [[[PlainView alloc] initWithFrame:
      NSMakeRect(100, 100, 82, 32)] autorelease];
    tight->dirty = [NSMutableArray new];
    [content addSubview: tight];
    [tight addSubview: a];
    [a setFrame: NSMakeRect(1, 1, 80, 30)];
    [window setDefaultButtonCell: [a cell]];
    PASS_RUNS([window display], "a ring wider than the superview draws");
    PASS(theme->draws > 0, "and it was called");
    PASS(!isRed(content, 98, 98), "nothing outside the superview");
    [a removeFromSuperview];
    [a setFrame: NSMakeRect(40, 40, 80, 30)];

    /* The default button inside a box */
    reset();
    outer = [[[PlainView alloc] initWithFrame:
      NSMakeRect(0, 0, 280, 180)] autorelease];
    outer->dirty = [NSMutableArray new];
    {
      NSBox	*box = [[[NSBox alloc] initWithFrame:
	NSMakeRect(10, 10, 280, 180)] autorelease];

      [box setContentView: outer];
      [content addSubview: box];
      [outer addSubview: a];
      [window setDefaultButtonCell: [a cell]];
      settle();
      [outer setNeedsDisplay: YES];
      [window displayIfNeeded];
      PASS(theme->lastView == outer, "in a box the box's content view paints");
      [box removeFromSuperview];
    }
  }

  /* A tab page */
  {
    NSTabView		*tabs;
    NSTabViewItem	*one;
    NSTabViewItem	*two;
    PlainView		*page;

    reset();
    tabs = [[[NSTabView alloc] initWithFrame:
      NSMakeRect(0, 0, 300, 200)] autorelease];
    one = [[[NSTabViewItem alloc] initWithIdentifier: @"one"] autorelease];
    two = [[[NSTabViewItem alloc] initWithIdentifier: @"two"] autorelease];
    page = [[[PlainView alloc] initWithFrame:
      NSMakeRect(0, 0, 280, 160)] autorelease];
    page->dirty = [NSMutableArray new];
    [page addSubview: a];
    [one setLabel: @"One"];
    [one setView: page];
    [two setLabel: @"Two"];
    [two setView: [[PlainView new] autorelease]];
    [tabs addTabViewItem: one];
    [tabs addTabViewItem: two];
    [content addSubview: tabs];
    [window setDefaultButtonCell: [a cell]];
    settle();
    [page setNeedsDisplay: YES];
    [window displayIfNeeded];
    PASS(theme->draws == 1 && theme->lastView == page, "on a tab page");
    theme->draws = 0;
    [tabs selectTabViewItem: two];
    [window displayIfNeeded];
    PASS(theme->draws == 0, "not while the page is not selected");
    [tabs selectTabViewItem: one];
    [window displayIfNeeded];
    PASS(theme->draws > 0, "back when it is");
    [tabs removeFromSuperview];
  }

  /* A cell of something that is not its button */
  {
    NSMatrix	*matrix;

    reset();
    matrix = [[[NSMatrix alloc] initWithFrame: NSMakeRect(10, 10, 100, 60)
      mode: NSTrackModeMatrix cellClass: [NSButtonCell class]
      numberOfRows: 2 numberOfColumns: 1] autorelease];
    [content addSubview: matrix];
    [window setDefaultButtonCell: [matrix cellAtRow: 0 column: 0]];
    [window display];
    PASS(theme->draws == 0, "no ring around a matrix");
    [matrix removeFromSuperview];
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
    PASS([cell controlView] == nil, "a cell does not outlive its control view");
    PASS_RUNS([window display], "the window still draws");
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
