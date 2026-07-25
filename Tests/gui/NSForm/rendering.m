/* A form with entries draws into a bitmap of its own size.  This is a render
   regression lock (GNUstep against itself), not a pixel comparison against
   AppKit.  The form uses the theme and font backend, so the set is skipped
   when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSForm.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSForm rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 60)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSForm *f = AUTORELEASE([[NSForm alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 60)]);
      [f addEntry: @"Name"];
      [f addEntry: @"Email"];
      [w setContentView: f];

      [f lockFocus];
      [f drawRect: [f bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 200, 60)]);
      [f unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 200 && [rep pixelsHigh] == 60,
        "a form renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSForm rendering")
  DESTROY(arp);
  return 0;
}
