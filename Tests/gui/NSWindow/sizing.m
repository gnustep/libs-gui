#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSWindow sizing")

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

      /* Sizing constraints round-trip. Checked against AppKit. */
      [w setMinSize: NSMakeSize(120, 90)];
      PASS(NSEqualSizes([w minSize], NSMakeSize(120, 90)), "setMinSize: round-trips");

      [w setMaxSize: NSMakeSize(800, 600)];
      PASS(NSEqualSizes([w maxSize], NSMakeSize(800, 600)), "setMaxSize: round-trips");

      [w setResizeIncrements: NSMakeSize(10, 5)];
      PASS(NSEqualSizes([w resizeIncrements], NSMakeSize(10, 5)),
        "setResizeIncrements: round-trips");

      [w setContentMinSize: NSMakeSize(100, 80)];
      PASS(NSEqualSizes([w contentMinSize], NSMakeSize(100, 80)),
        "setContentMinSize: round-trips");

      [w setContentMaxSize: NSMakeSize(700, 500)];
      PASS(NSEqualSizes([w contentMaxSize], NSMakeSize(700, 500)),
        "setContentMaxSize: round-trips");

      [w setLevel: 5];
      PASS([w level] == 5, "setLevel: round-trips");

      PASS([w styleMask] == NSWindowStyleMaskBorderless,
        "a borderless window reports the borderless style mask");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow sizing")
  DESTROY(arp);
  return 0;
}
