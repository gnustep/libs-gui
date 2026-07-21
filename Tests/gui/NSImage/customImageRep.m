/* An NSImage backed by an NSCustomImageRep draws through its delegate on every
   draw, so changing what the delegate paints changes the image.  The rep used
   to be cached after the first draw, freezing its output.  A custom rep is
   drawn red, then its delegate is switched to blue and it is drawn again; the
   second drawing must be blue.  Drawing needs the theme and font backend, so
   the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSView.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSCustomImageRep.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSGraphics.h>

@interface Painter : NSObject
{
@public
  NSColor *color;
}
@end

@implementation Painter
- (void) drawRep: (NSCustomImageRep *)rep
{
  [color set];
  NSRectFill(NSMakeRect(0, 0, 32, 32));
}
@end

/* Draws the image into an offscreen bitmap and returns its centre colour. */
static NSColor *
renderCentre(NSImage *img)
{
  NSWindow *w = AUTORELEASE([[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 32, 32)
              styleMask: NSWindowStyleMaskBorderless
                backing: NSBackingStoreBuffered
                  defer: NO]);
  NSView *v = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 32, 32)]);
  [w setContentView: v];

  [v lockFocus];
  [img drawInRect: NSMakeRect(0, 0, 32, 32)
         fromRect: NSZeroRect
        operation: NSCompositeCopy
         fraction: 1.0];
  NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithFocusedViewRect: NSMakeRect(0, 0, 32, 32)]);
  [v unlockFocus];

  return [[rep colorAtX: 16 y: 16]
    colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSImage customImageRep")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NS_DURING
    {
      Painter *p = AUTORELEASE([Painter new]);
      p->color = [NSColor redColor];

      NSCustomImageRep *rep = AUTORELEASE([[NSCustomImageRep alloc]
        initWithDrawSelector: @selector(drawRep:) delegate: p]);
      [rep setSize: NSMakeSize(32, 32)];

      NSImage *img = AUTORELEASE([[NSImage alloc]
        initWithSize: NSMakeSize(32, 32)]);
      [img addRepresentation: rep];

      NSColor *first = renderCentre(img);
      pass(first != nil && [first redComponent] > 0.9
           && [first blueComponent] < 0.1,
           "the custom rep draws red the first time");

      p->color = [NSColor blueColor];
      NSColor *second = renderCentre(img);
      pass(second != nil && [second blueComponent] > 0.9
           && [second redComponent] < 0.1,
           "the custom rep redraws in the new colour, not a stale cache");
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSImage customImageRep")

  DESTROY(arp);
  return 0;
}
