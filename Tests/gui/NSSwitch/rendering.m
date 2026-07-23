/* A switch draws into a bitmap of its own size.  This is a render regression
   lock (GNUstep against itself), not a pixel comparison against AppKit.  The
   switch uses the theme and font backend, so the set is skipped when the
   backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSSwitch.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSwitch rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 40, 24)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSSwitch *sw = AUTORELEASE([[NSSwitch alloc]
        initWithFrame: NSMakeRect(0, 0, 40, 24)]);
      [sw setState: NSControlStateValueOn];
      [w setContentView: sw];

      [sw lockFocus];
      [sw drawRect: [sw bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 40, 24)]);
      [sw unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 40 && [rep pixelsHigh] == 24,
        "a switch renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSwitch rendering")
  DESTROY(arp);
  return 0;
}
