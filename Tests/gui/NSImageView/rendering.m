/* An image view with a frame style draws into a bitmap of its own size.  This
   is a render regression lock (GNUstep against itself), not a pixel comparison
   against AppKit.  The view uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSImageView.h>
#import <AppKit/NSImageCell.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSImageView rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 60, 60)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSImageView *iv = AUTORELEASE([[NSImageView alloc]
        initWithFrame: NSMakeRect(0, 0, 60, 60)]);
      [iv setImageFrameStyle: NSImageFrameGrayBezel];
      [w setContentView: iv];

      [iv lockFocus];
      [iv drawRect: [iv bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 60, 60)]);
      [iv unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 60 && [rep pixelsHigh] == 60,
        "an image view renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSImageView rendering")
  DESTROY(arp);
  return 0;
}
