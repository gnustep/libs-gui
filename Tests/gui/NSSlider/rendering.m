/* A slider draws through its cell into a bitmap of its own size.  This is a
   render regression lock (GNUstep against itself), not a pixel comparison
   against AppKit.  The slider uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSSlider.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSlider rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 24)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSSlider *s = AUTORELEASE([[NSSlider alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 24)]);
      [s setMinValue: 0.0];
      [s setMaxValue: 10.0];
      [s setDoubleValue: 5.0];
      [w setContentView: s];

      [s lockFocus];
      [s drawRect: [s bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 120, 24)]);
      [s unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 120 && [rep pixelsHigh] == 24,
        "a slider renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSlider rendering")
  DESTROY(arp);
  return 0;
}
