#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSBitmapImageRep.h>

@interface RedContent : NSView
@end
@implementation RedContent
- (void) drawRect: (NSRect)r
{
  [[NSColor redColor] set];
  NSRectFill([self bounds]);
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSWindow content rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 16, 16)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      RedContent *v = AUTORELEASE([[RedContent alloc]
        initWithFrame: NSMakeRect(0, 0, 16, 16)]);
      [w setContentView: v];

      /* The window's content view renders through the offscreen path (a
         regression lock, not a pixel comparison against AppKit). */
      [v lockFocus];
      [v drawRect: [v bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 16, 16)]);
      [v unlockFocus];

      NSColor *c = [[rep colorAtX: 8 y: 8]
        colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      PASS(c != nil && [c redComponent] > 0.9
        && [c greenComponent] < 0.1 && [c blueComponent] < 0.1,
        "the window content view renders red at its centre");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow content rendering")
  DESTROY(arp);
  return 0;
}
