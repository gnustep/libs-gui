#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSView.h>

/* -[NSView visibleRect] on a view with no window reports an unbounded
   rectangle, matching AppKit (checked on a macOS runner: origin
   {-CGFLOAT_MAX/2, -CGFLOAT_MAX/2}, size {CGFLOAT_MAX, CGFLOAT_MAX}).  A hidden
   view still reports NSZeroRect.  This needs no window server. */

static const CGFloat huge = 1.0e30;

static BOOL
isUnbounded(NSRect r)
{
  return (r.size.width > huge) && (r.size.height > huge)
    && (r.origin.x < -huge) && (r.origin.y < -huge);
}

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSView *v, *sup, *child, *hidden;

  v = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 80)]);
  PASS(isUnbounded([v visibleRect]),
       "a windowless view has an unbounded visibleRect");
  PASS(NSContainsRect([v visibleRect], [v bounds]),
       "the unbounded visibleRect contains the view bounds");

  sup = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 200)]);
  child = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(10, 10, 50, 50)]);
  [sup addSubview: child];
  PASS(isUnbounded([child visibleRect]),
       "a windowless view inside a windowless superview is also unbounded");
  PASS(isUnbounded([sup visibleRect]),
       "the windowless superview is unbounded too");

  hidden = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 80)]);
  [hidden setHidden: YES];
  PASS(NSEqualRects([hidden visibleRect], NSZeroRect),
       "a hidden windowless view has a zero visibleRect");

  DESTROY(arp);
  return 0;
}
