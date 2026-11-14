/* A view that returns NO from -wantsDefaultClipping is not clipped to its
 * bounds, so it can draw outside its frame.  What it draws there has to be
 * kept: the superview redisplays it wherever it redraws, and its own
 * invalidation is not cut off at its bounds.  A view that returns YES is
 * clipped as before.
 *
 * The pixels are read back from the window, so the test needs a display.
 */
#include "Testing.h"
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#define SPILL 10.0

@interface WhiteView : NSView
@end

@implementation WhiteView
- (void) drawRect: (NSRect)r
{
  [[NSColor whiteColor] set];
  NSRectFill(r);
}
@end

/* Fills its bounds and SPILL points around them. */
@interface SpillView : NSView
{
@public
  BOOL		clips;
  NSColor	*color;
}
@end

@implementation SpillView
- (BOOL) wantsDefaultClipping
{
  return clips;
}
- (void) drawRect: (NSRect)r
{
  NSRectClip(r);
  [color set];
  NSRectFill(NSInsetRect([self bounds], -SPILL, -SPILL));
}
@end

static NSWindow		*window;
static WhiteView	*content;

static NSColor *
pixel(CGFloat x, CGFloat y)
{
  NSBitmapImageRep	*rep;
  NSColor		*c;

  [content lockFocus];
  rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:
    NSMakeRect(x, y, 1, 1)];
  [content unlockFocus];
  c = [[rep colorAtX: 0 y: 0]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  [rep release];
  return c;
}

static BOOL
isBlue(CGFloat x, CGFloat y)
{
  NSColor	*c = pixel(x, y);

  return [c blueComponent] > 0.9 && [c redComponent] < 0.1;
}

static BOOL
isRed(CGFloat x, CGFloat y)
{
  NSColor	*c = pixel(x, y);

  return [c redComponent] > 0.9 && [c blueComponent] < 0.1;
}

static BOOL
isWhite(CGFloat x, CGFloat y)
{
  NSColor	*c = pixel(x, y);

  return [c redComponent] > 0.9 && [c greenComponent] > 0.9
    && [c blueComponent] > 0.9;
}

static SpillView *
makeView(BOOL clips)
{
  SpillView	*v;

  v = [[[SpillView alloc] initWithFrame: NSMakeRect(100, 80, 60, 40)]
    autorelease];
  v->clips = clips;
  v->color = [NSColor blueColor];
  [content addSubview: v];
  [window display];
  return v;
}

int
main(int argc, char **argv)
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];
  SpillView		*v;

  START_SET("NSView wantsDefaultClipping")

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

  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(50, 50, 300, 200)
				       styleMask: NSBorderlessWindowMask
					 backing: NSBackingStoreBuffered
					   defer: NO];
  content = [[WhiteView alloc] initWithFrame: NSMakeRect(0, 0, 300, 200)];
  [window setContentView: content];
  [window orderFrontRegardless];

  v = makeView(YES);
  PASS([[[[NSView alloc] init] autorelease] wantsDefaultClipping],
    "a view wants the default clipping");
  PASS(isBlue(130, 100), "a clipped view draws inside its frame");
  PASS(isWhite(95, 100) && isWhite(130, 125),
    "but not outside of it");
  [v removeFromSuperview];
  [window display];

  v = makeView(NO);
  PASS(isBlue(130, 100), "a view that does not clip draws inside its frame");
  PASS(isBlue(95, 100) && isBlue(130, 125) && isBlue(165, 75),
    "and outside of it");
  PASS(isWhite(85, 100), "only where it draws");

  [content setNeedsDisplayInRect: NSMakeRect(92, 95, 4, 4)];
  [window displayIfNeeded];
  PASS(isBlue(95, 97),
    "the superview redrawing next to its frame draws it again");

  v->color = [NSColor redColor];
  [v setNeedsDisplay: YES];
  [window displayIfNeeded];
  PASS(isRed(130, 100) && isRed(95, 100) && isRed(165, 75),
    "-setNeedsDisplay: covers what it draws outside its frame");

  v->color = [NSColor blueColor];
  [v setNeedsDisplayInRect: NSMakeRect(-8, 10, 4, 4)];
  [window displayIfNeeded];
  PASS(isBlue(94, 92), "-setNeedsDisplayInRect: is not cut at its bounds");

  [v setFrameOrigin: NSMakePoint(100, 20)];
  [window displayIfNeeded];
  PASS(isWhite(95, 100), "moving it leaves nothing behind");
  PASS(isBlue(95, 40), "and it draws at the new place");

  [v setHidden: YES];
  [window displayIfNeeded];
  PASS(isWhite(95, 40), "hiding it leaves nothing behind");
  [v setHidden: NO];
  [window displayIfNeeded];
  PASS(isBlue(95, 40), "showing it draws it again");

  [v removeFromSuperview];
  [window displayIfNeeded];
  PASS(isWhite(95, 40), "removing it leaves nothing behind");

  [window orderOut: nil];
  END_SET("NSView wantsDefaultClipping")

  [pool release];
  return 0;
}
