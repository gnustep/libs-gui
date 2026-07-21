#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSClipView rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 16, 16)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSClipView *clip = AUTORELEASE([[NSClipView alloc]
        initWithFrame: NSMakeRect(0, 0, 16, 16)]);
      [clip setDrawsBackground: YES];
      [clip setBackgroundColor: [NSColor redColor]];
      [w setContentView: clip];

      /* The clip view fills its background (a regression lock, not a pixel
         comparison against AppKit). */
      NSRect b = [clip bounds];
      [clip lockFocus];
      [clip drawRect: b];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: b]);
      [clip unlockFocus];

      NSColor *c = [[rep colorAtX: [rep pixelsWide] / 2 y: [rep pixelsHigh] / 2]
        colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      PASS(c != nil && [c redComponent] > 0.9
        && [c greenComponent] < 0.1 && [c blueComponent] < 0.1,
        "a clip view renders its background red");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSClipView rendering")
  DESTROY(arp);
  return 0;
}
