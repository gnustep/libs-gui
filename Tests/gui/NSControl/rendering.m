#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSActionCell.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSControl rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 60, 24)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSControl *c = AUTORELEASE([[NSControl alloc]
        initWithFrame: NSMakeRect(0, 0, 60, 24)]);
      [c setCell: AUTORELEASE([[NSActionCell alloc] initTextCell: @"x"])];
      [w setContentView: c];

      /* The control draws through its cell without error and produces a
         bitmap of its own size (a render regression lock, not a pixel
         comparison against AppKit). */
      [c lockFocus];
      [c drawRect: [c bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 60, 24)]);
      [c unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 60 && [rep pixelsHigh] == 24,
        "a control renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSControl rendering")
  DESTROY(arp);
  return 0;
}
