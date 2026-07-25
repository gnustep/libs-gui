/* A determinate progress indicator draws into a bitmap of its own size.  This
   is a render regression lock (GNUstep against itself), not a pixel comparison
   against AppKit.  The indicator uses the theme and font backend, so the set
   is skipped when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSProgressIndicator.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSProgressIndicator rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 160, 20)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSProgressIndicator *pi = AUTORELEASE([[NSProgressIndicator alloc]
        initWithFrame: NSMakeRect(0, 0, 160, 20)]);
      [pi setIndeterminate: NO];
      [pi setMinValue: 0.0];
      [pi setMaxValue: 100.0];
      [pi setDoubleValue: 60.0];
      [w setContentView: pi];

      [pi lockFocus];
      [pi drawRect: [pi bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 160, 20)]);
      [pi unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 160 && [rep pixelsHigh] == 20,
        "a progress indicator renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSProgressIndicator rendering")
  DESTROY(arp);
  return 0;
}
