#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>

/* Values checked against AppKit. */

@interface ConvertFlippedView : NSView
@end
@implementation ConvertFlippedView
- (BOOL) isFlipped
{
  return YES;
}
@end

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSView convert")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* windowless hierarchy: display-independent */
  {
    NSView *outer = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 200)]);
    NSView *inner = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(50, 30, 100, 100)]);
    [outer addSubview: inner];

    NSPoint p1 = [inner convertPoint: NSMakePoint(10, 10) toView: outer];
    PASS(NSEqualPoints(p1, NSMakePoint(60, 40)),
      "convertPoint:toView: inner to outer offsets by the subview origin");

    NSPoint p2 = [outer convertPoint: NSMakePoint(10, 10) toView: inner];
    PASS(NSEqualPoints(p2, NSMakePoint(-40, -20)),
      "convertPoint:toView: outer to inner offsets by the negative subview origin");

    NSPoint p3 = [outer convertPoint: NSMakePoint(10, 10) fromView: inner];
    PASS(NSEqualPoints(p3, NSMakePoint(60, 40)),
      "convertPoint:fromView: inner to outer matches convertPoint:toView:");

    NSPoint p4 = [inner convertPoint: NSMakePoint(10, 10) fromView: outer];
    PASS(NSEqualPoints(p4, NSMakePoint(-40, -20)),
      "convertPoint:fromView: outer to inner matches convertPoint:toView:");

    NSPoint back = [outer convertPoint: p1 toView: inner];
    PASS(NSEqualPoints(back, NSMakePoint(10, 10)),
      "convertPoint:toView: round-trips");

    PASS([inner isFlipped] == NO, "a plain NSView is not flipped");

    NSSize s1 = [inner convertSize: NSMakeSize(20, 20) toView: outer];
    PASS(NSEqualSizes(s1, NSMakeSize(20, 20)),
      "convertSize:toView: inner to outer is unchanged (no scale)");

    NSSize s2 = [outer convertSize: NSMakeSize(20, 20) toView: inner];
    PASS(NSEqualSizes(s2, NSMakeSize(20, 20)),
      "convertSize:toView: outer to inner is unchanged (no scale)");

    NSSize s3 = [outer convertSize: NSMakeSize(20, 20) fromView: inner];
    PASS(NSEqualSizes(s3, NSMakeSize(20, 20)),
      "convertSize:fromView: inner to outer is unchanged (no scale)");

    NSSize s4 = [inner convertSize: NSMakeSize(20, 20) fromView: outer];
    PASS(NSEqualSizes(s4, NSMakeSize(20, 20)),
      "convertSize:fromView: outer to inner is unchanged (no scale)");

    /* convertRect:toView:/fromView: on a windowless hierarchy no-ops in
       GNUstep instead of applying the hierarchy transform; that is a
       confirmed divergence from AppKit, recorded in the values doc and
       left out of this suite (see Divergences). */

    /* through a flipped subview */
    NSView *flippedOuter = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 200, 200)]);
    ConvertFlippedView *flippedInner = AUTORELEASE([[ConvertFlippedView alloc] initWithFrame: NSMakeRect(50, 30, 100, 100)]);
    [flippedOuter addSubview: flippedInner];

    NSPoint fp1 = [flippedInner convertPoint: NSMakePoint(10, 10) toView: flippedOuter];
    PASS(NSEqualPoints(fp1, NSMakePoint(60, 120)),
      "convertPoint:toView: through a flipped subview, inner to outer");

    NSPoint fp2 = [flippedOuter convertPoint: NSMakePoint(10, 10) toView: flippedInner];
    PASS(NSEqualPoints(fp2, NSMakePoint(-40, 120)),
      "convertPoint:toView: through a flipped subview, outer to inner");

    /* convertRect:toView: through a flipped subview is windowless too, so
       it hits the same no-op divergence noted above (see Divergences). */

    NSSize fs1 = [flippedInner convertSize: NSMakeSize(20, 20) toView: flippedOuter];
    PASS(NSEqualSizes(fs1, NSMakeSize(20, 20)),
      "convertSize:toView: through a flipped subview is unchanged (no scale)");
  }

  END_SET("NSView convert")

  /* windowed hierarchy and nil (window base coordinates): needs a display */
  START_SET("NSView convert (windowed)")
  NS_DURING
    {
      [NSApplication sharedApplication];
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *wOuter = [w contentView];
      NSView *wInner = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(50, 30, 100, 100)]);
      [wOuter addSubview: wInner];

      NSPoint wp1 = [wInner convertPoint: NSMakePoint(10, 10) toView: wOuter];
      PASS(NSEqualPoints(wp1, NSMakePoint(60, 40)),
        "convertPoint:toView: inner to outer (windowed)");

      NSPoint wp2 = [wOuter convertPoint: NSMakePoint(10, 10) toView: wInner];
      PASS(NSEqualPoints(wp2, NSMakePoint(-40, -20)),
        "convertPoint:toView: outer to inner (windowed)");

      NSPoint wp3 = [wOuter convertPoint: NSMakePoint(10, 10) fromView: wInner];
      PASS(NSEqualPoints(wp3, NSMakePoint(60, 40)),
        "convertPoint:fromView: inner to outer (windowed)");

      NSPoint wp4 = [wInner convertPoint: NSMakePoint(10, 10) fromView: wOuter];
      PASS(NSEqualPoints(wp4, NSMakePoint(-40, -20)),
        "convertPoint:fromView: outer to inner (windowed)");

      NSRect wr1 = [wInner convertRect: NSMakeRect(10, 10, 20, 20) toView: wOuter];
      PASS(NSEqualRects(wr1, NSMakeRect(60, 40, 20, 20)),
        "convertRect:toView: inner to outer (windowed)");

      NSRect wr2 = [wOuter convertRect: NSMakeRect(10, 10, 20, 20) toView: wInner];
      PASS(NSEqualRects(wr2, NSMakeRect(-40, -20, 20, 20)),
        "convertRect:toView: outer to inner (windowed)");

      NSRect wr3 = [wOuter convertRect: NSMakeRect(10, 10, 20, 20) fromView: wInner];
      PASS(NSEqualRects(wr3, NSMakeRect(60, 40, 20, 20)),
        "convertRect:fromView: inner to outer (windowed)");

      NSRect wr4 = [wInner convertRect: NSMakeRect(10, 10, 20, 20) fromView: wOuter];
      PASS(NSEqualRects(wr4, NSMakeRect(-40, -20, 20, 20)),
        "convertRect:fromView: outer to inner (windowed)");

      NSSize ws1 = [wInner convertSize: NSMakeSize(20, 20) toView: wOuter];
      PASS(NSEqualSizes(ws1, NSMakeSize(20, 20)),
        "convertSize:toView: inner to outer is unchanged (windowed)");

      NSSize ws2 = [wOuter convertSize: NSMakeSize(20, 20) toView: wInner];
      PASS(NSEqualSizes(ws2, NSMakeSize(20, 20)),
        "convertSize:toView: outer to inner is unchanged (windowed)");

      /* nil view: window base coordinates */
      NSPoint nilPt = [wInner convertPoint: NSMakePoint(10, 10) toView: nil];
      PASS(NSEqualPoints(nilPt, NSMakePoint(60, 40)),
        "convertPoint:toView: nil converts to window base coordinates");

      NSPoint backPt = [wInner convertPoint: nilPt fromView: nil];
      PASS(NSEqualPoints(backPt, NSMakePoint(10, 10)),
        "convertPoint:fromView: nil round-trips from window base coordinates");

      NSRect nilRect = [wInner convertRect: NSMakeRect(10, 10, 20, 20) toView: nil];
      PASS(NSEqualRects(nilRect, NSMakeRect(60, 40, 20, 20)),
        "convertRect:toView: nil converts to window base coordinates");

      NSRect backRect = [wInner convertRect: nilRect fromView: nil];
      PASS(NSEqualRects(backRect, NSMakeRect(10, 10, 20, 20)),
        "convertRect:fromView: nil round-trips from window base coordinates");

      NSSize nilSize = [wInner convertSize: NSMakeSize(20, 20) toView: nil];
      PASS(NSEqualSizes(nilSize, NSMakeSize(20, 20)),
        "convertSize:toView: nil is unchanged (no scale)");

      NSSize backSize = [wInner convertSize: nilSize fromView: nil];
      PASS(NSEqualSizes(backSize, NSMakeSize(20, 20)),
        "convertSize:fromView: nil round-trips (no scale)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER
  END_SET("NSView convert (windowed)")

  DESTROY(arp);
  return 0;
}
