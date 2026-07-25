#import "Testing.h"
#import "../GSRenderTest.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSView.h>

/* Records the frame passed to drawWithFrame:inView: without drawing, so the
   forwarding contract can be checked without a real drawing context. */
@interface ForwardCell : NSCell
{
@public
  BOOL drew;
  NSRect drewFrame;
}
@end

@implementation ForwardCell
- (void) drawWithFrame: (NSRect)f inView: (NSView *)v
{
  drew = YES;
  drewFrame = f;
}
@end

/* Draws a base NSCell focus ring mask in black so the filled region can be
   sampled. */
@interface MaskView : NSView
@end

@implementation MaskView
- (void) drawRect: (NSRect)r
{
  NSCell *cell = AUTORELEASE([[NSCell alloc] initTextCell: @""]);

  [[NSColor whiteColor] set];
  NSRectFill([self bounds]);
  [[NSColor blackColor] set];
  [cell drawFocusRingMaskWithFrame: NSMakeRect(6, 6, 28, 16) inView: self];
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  ForwardCell *cell;
  MaskView *view;
  NSBitmapImageRep *rep;
  NSRect expansion = NSMakeRect(3, 5, 40, 18);

  START_SET("NSCell drawing defaults")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  /* drawWithExpansionFrame:inView: draws the cell in the expansion frame by
     calling drawWithFrame:inView: with that frame.  Checked against AppKit. */
  cell = AUTORELEASE([[ForwardCell alloc] initTextCell: @"hello"]);
  cell->drew = NO;
  [cell drawWithExpansionFrame: expansion inView: nil];
  PASS(cell->drew == YES,
    "drawWithExpansionFrame:inView: draws the cell");
  PASS(NSEqualRects(cell->drewFrame, expansion),
    "drawWithExpansionFrame:inView: draws with the expansion frame");

  /* drawFocusRingMaskWithFrame:inView: fills the cell frame. */
  view = AUTORELEASE([[MaskView alloc] initWithFrame: NSMakeRect(0, 0, 40, 28)]);
  rep = GSRenderView(view);
  PASS(GSRegionHasContent(rep, NSMakeRect(10, 10, 20, 8)),
    "drawFocusRingMaskWithFrame:inView: fills the frame");

  END_SET("NSCell drawing defaults")

  DESTROY(arp);
  return 0;
}
