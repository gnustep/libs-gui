#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSView hitTest")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 200)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSView *outer = [w contentView];
      NSView *inner = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(50, 50, 100, 100)]);
      [outer addSubview: inner];

      /* hitTest: is called on the outer view with a point in its superview
         (window base) coordinates. Checked against AppKit. */
      PASS([outer hitTest: NSMakePoint(60, 60)] == inner,
        "hitTest: returns the inner subview for a point inside it");
      PASS([outer hitTest: NSMakePoint(10, 10)] == outer,
        "hitTest: returns the outer view for a point outside the subview");
      PASS([outer hitTest: NSMakePoint(300, 300)] == nil,
        "hitTest: returns nil for a point outside the view");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSView hitTest")
  DESTROY(arp);
  return 0;
}
