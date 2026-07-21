#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>

@interface Swatch : NSView
@end
@implementation Swatch
- (void) drawRect: (NSRect)r
{
  [[NSColor redColor] set];
  NSRectFill([self bounds]);
}
@end

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSView rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSBitmapImageRep *rep = nil;

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 16, 16)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      Swatch *v = AUTORELEASE([[Swatch alloc] initWithFrame: NSMakeRect(0, 0, 16, 16)]);
      [w setContentView: v];

      [v lockFocus];
      [v drawRect: [v bounds]];
      rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 16, 16)]);
      [v unlockFocus];
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available to render into")
  NS_ENDHANDLER

  PASS(rep != nil && [rep pixelsWide] == 16 && [rep pixelsHigh] == 16,
    "offscreen render produced a 16x16 bitmap");

  /* NSBitmapImageRep pixel coordinates originate at the top-left, unlike
     the view's bottom-left, so a replicator reading a non-uniform render
     must flip y to land on the same point as the view-space rect above. */
  NSColor *c = [[rep colorAtX: 8 y: 8]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  PASS(c != nil && [c redComponent] > 0.9
    && [c greenComponent] < 0.1 && [c blueComponent] < 0.1,
    "centre pixel of a red-fill view is red");

  END_SET("NSView rendering")
  DESTROY(arp);
  return 0;
}
