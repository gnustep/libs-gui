/* A bordered button draws through its cell into a bitmap of its own size.
   This is a render regression lock (GNUstep against itself), not a pixel
   comparison against AppKit.  The button uses the theme and font backend, so
   the set is skipped when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSButton rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 100, 24)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSButton *b = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 24)]);
      [b setTitle: @"Press"];
      [w setContentView: b];

      [b lockFocus];
      [b drawRect: [b bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 100, 24)]);
      [b unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 100 && [rep pixelsHigh] == 24,
        "a button renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSButton rendering")
  DESTROY(arp);
  return 0;
}
