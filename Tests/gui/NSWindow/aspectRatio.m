#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSWindow aspectRatio")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 150)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);

      [w setResizeIncrements: NSMakeSize(16, 16)];
      [w setAspectRatio: NSMakeSize(4, 3)];
      PASS(NSEqualSizes([w aspectRatio], NSMakeSize(4, 3)),
        "setAspectRatio: round-trips");
      PASS(NSEqualSizes([w resizeIncrements], NSZeroSize),
        "setAspectRatio: clears the resize increments");

      [w setResizeIncrements: NSMakeSize(8, 8)];
      PASS(NSEqualSizes([w resizeIncrements], NSMakeSize(8, 8)),
        "setResizeIncrements: round-trips");
      PASS(NSEqualSizes([w aspectRatio], NSZeroSize),
        "setResizeIncrements: clears the aspect ratio");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow aspectRatio")
  DESTROY(arp);
  return 0;
}
