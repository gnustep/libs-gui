/* A borderless color well fills its interior with its colour.  This is a
   render regression lock (GNUstep against itself), not a pixel comparison
   against AppKit.  The well uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
*/
#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSColorWell.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSGraphics.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSColorWell rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 40, 40)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSColorWell *cw = AUTORELEASE([[NSColorWell alloc]
        initWithFrame: NSMakeRect(0, 0, 40, 40)]);
      [cw setBordered: NO];
      [cw setColor: [NSColor redColor]];
      [w setContentView: cw];

      [cw lockFocus];
      [cw drawRect: [cw bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 40, 40)]);
      [cw unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 40 && [rep pixelsHigh] == 40,
        "a color well renders into a bitmap of its bounds");

      NSColor *centre = [[rep colorAtX: 20 y: 20]
        colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      PASS(centre != nil
           && [centre redComponent] > 0.9
           && [centre greenComponent] < 0.1
           && [centre blueComponent] < 0.1,
        "the interior is filled with the red colour");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSColorWell rendering")
  DESTROY(arp);
  return 0;
}
