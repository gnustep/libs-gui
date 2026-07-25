/* A date picker draws through its cell into a bitmap of its own size.  This is
   a render regression lock (GNUstep against itself), not a pixel comparison
   against AppKit.  The picker uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSDate.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSDatePicker.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSDatePicker rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 180, 24)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSDatePicker *dp = AUTORELEASE([[NSDatePicker alloc]
        initWithFrame: NSMakeRect(0, 0, 180, 24)]);
      [dp setDateValue: [NSDate dateWithTimeIntervalSinceReferenceDate: 700000000.0]];
      [w setContentView: dp];

      [dp lockFocus];
      [dp drawRect: [dp bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 180, 24)]);
      [dp unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 180 && [rep pixelsHigh] == 24,
        "a date picker renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSDatePicker rendering")
  DESTROY(arp);
  return 0;
}
