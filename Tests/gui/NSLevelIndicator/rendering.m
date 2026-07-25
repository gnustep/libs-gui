/* A level indicator draws through its cell into a bitmap of its own size.
   This is a render regression lock (GNUstep against itself), not a pixel
   comparison against AppKit.  The indicator uses the theme and font backend,
   so the set is skipped when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSLevelIndicator.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSLevelIndicator rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 20)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSLevelIndicator *li = AUTORELEASE([[NSLevelIndicator alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 20)]);
      [li setMinValue: 0.0];
      [li setMaxValue: 10.0];
      [li setDoubleValue: 6.0];
      [w setContentView: li];

      [li lockFocus];
      [li drawRect: [li bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 120, 20)]);
      [li unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 120 && [rep pixelsHigh] == 20,
        "a level indicator renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSLevelIndicator rendering")
  DESTROY(arp);
  return 0;
}
