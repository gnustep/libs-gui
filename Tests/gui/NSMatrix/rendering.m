#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSBitmapImageRep.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSMatrix rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 100, 60)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSButtonCell *proto = AUTORELEASE([[NSButtonCell alloc] init]);
      NSMatrix *m = AUTORELEASE([[NSMatrix alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 60)
                 mode: NSRadioModeMatrix
            prototype: proto
         numberOfRows: 2
      numberOfColumns: 2]);
      [w setContentView: m];

      /* The matrix draws its cells without error and produces a bitmap of its
         own size (a render regression lock, not a pixel comparison against
         AppKit). */
      [m lockFocus];
      [m drawRect: [m bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 100, 60)]);
      [m unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 100 && [rep pixelsHigh] == 60,
        "a matrix renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMatrix rendering")
  DESTROY(arp);
  return 0;
}
