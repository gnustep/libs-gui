#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSWindow cascade")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 100, 100)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);

      /* A cascade offsets the next window down and to the right; the offset
         magnitude is a system metric and is not asserted. */
      NSPoint p1 = [w cascadeTopLeftFromPoint: NSMakePoint(50, 300)];
      PASS(p1.x > 50 && p1.y < 300,
        "cascadeTopLeftFromPoint: cascades down and to the right");

      NSPoint p2 = [w cascadeTopLeftFromPoint: p1];
      PASS(p2.x > p1.x && p2.y < p1.y,
        "cascadeTopLeftFromPoint: advances the cascade on each call");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow cascade")
  DESTROY(arp);
  return 0;
}
