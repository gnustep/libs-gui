#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSSplitView.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSplitView rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 100)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSSplitView *sv = AUTORELEASE([[NSSplitView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 100)]);
      [sv addSubview: AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 45)])];
      [sv addSubview: AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 45)])];
      [sv adjustSubviews];
      [w setContentView: sv];

      /* The split view draws its subviews and divider without error and
         produces a bitmap of its own size (a render regression lock, not a
         pixel comparison against AppKit). */
      [sv lockFocus];
      [sv drawRect: [sv bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 120, 100)]);
      [sv unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 120 && [rep pixelsHigh] == 100,
        "a split view renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSplitView rendering")
  DESTROY(arp);
  return 0;
}
