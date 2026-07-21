#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>

@interface FlippedSuper : NSView
@end
@implementation FlippedSuper
- (BOOL) isFlipped
{
  return YES;
}
@end

static NSRect
resized(Class superClass, NSUInteger mask)
{
  NSView *sup = AUTORELEASE([[superClass alloc]
			      initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  NSView *sub = AUTORELEASE([[NSView alloc]
			      initWithFrame: NSMakeRect(10, 10, 30, 30)]);

  [sup setAutoresizesSubviews: YES];
  [sub setAutoresizingMask: mask];
  [sup addSubview: sub];
  [sup setFrameSize: NSMakeSize(200, 150)];
  return [sub frame];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSView autoresize flip invariance")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* AppKit resizes a subview the same whether or not the superview is
     flipped: the autoresizing mask applies to the frame coordinates and is
     not reinterpreted by the superview's flip state. Checked against
     AppKit. */
  PASS(NSEqualRects(resized([NSView class],
			    NSViewHeightSizable | NSViewMinYMargin),
		    resized([FlippedSuper class],
			    NSViewHeightSizable | NSViewMinYMargin)),
    "minYMargin autoresize is unchanged by a flipped superview");

  PASS(NSEqualRects(resized([NSView class],
			    NSViewHeightSizable | NSViewMaxYMargin),
		    resized([FlippedSuper class],
			    NSViewHeightSizable | NSViewMaxYMargin)),
    "maxYMargin autoresize is unchanged by a flipped superview");

  END_SET("NSView autoresize flip invariance")
  DESTROY(arp);
  return 0;
}
