#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSView geometry")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSView *outer = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 200)]);
  NSView *inner = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(50, 30, 100, 100)]);
  [outer addSubview: inner];

  /* A point in inner's coordinates, expressed in outer's coordinates, is
     offset by inner's origin (both views unflipped). Values verified on
     AppKit. */
  NSPoint p = [inner convertPoint: NSMakePoint(10, 10) toView: outer];
  PASS(NSEqualPoints(p, NSMakePoint(60, 40)),
    "convertPoint:toView: offsets by the subview origin");

  NSPoint back = [outer convertPoint: p toView: inner];
  PASS(NSEqualPoints(back, NSMakePoint(10, 10)),
    "convertPoint:toView: round-trips");

  PASS([inner isFlipped] == NO, "a plain NSView is not flipped");

  END_SET("NSView geometry")
  DESTROY(arp);
  return 0;
}
