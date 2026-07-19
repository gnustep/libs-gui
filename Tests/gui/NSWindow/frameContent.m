#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSWindow frame and content")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSRect fr = NSMakeRect(10, 20, 200, 150);

      /* A borderless window has no decoration, so content and frame rects are
         equal. Checked against AppKit. */
      PASS(NSEqualRects([NSWindow contentRectForFrameRect: fr
                                              styleMask: NSWindowStyleMaskBorderless], fr),
        "+contentRectForFrameRect:styleMask: is identity for a borderless window");
      PASS(NSEqualRects([NSWindow frameRectForContentRect: fr
                                              styleMask: NSWindowStyleMaskBorderless], fr),
        "+frameRectForContentRect:styleMask: is identity for a borderless window");

      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 150)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      PASS(NSEqualRects([w frame], NSMakeRect(0, 0, 200, 150)),
        "a borderless window frame equals its content rect");
      PASS(NSEqualRects([w contentRectForFrameRect: fr], fr),
        "-contentRectForFrameRect: is identity for a borderless window");
      PASS(NSEqualRects([w frameRectForContentRect: fr], fr),
        "-frameRectForContentRect: is identity for a borderless window");

      [w setContentSize: NSMakeSize(300, 250)];
      PASS(NSEqualSizes([w frame].size, NSMakeSize(300, 250)),
        "setContentSize: sets the frame size of a borderless window");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow frame and content")
  DESTROY(arp);
  return 0;
}
