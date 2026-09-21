#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSView.h>

int
main(int argc, const char **argv)
{
  START_SET("NSClipView constrain")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSClipView *clip = AUTORELEASE([[NSClipView alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);
      NSView *doc = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 500, 500)]);
      [clip setDocumentView: doc];

      PASS(NSEqualRects([clip documentRect], NSMakeRect(0, 0, 500, 500)),
        "documentRect is the document frame");

      /* constrainScrollPoint: clamps a proposed origin to the valid scroll
         range (0..400 for a 500x500 document in a 100x100 clip view). Checked
         against AppKit. */
      PASS(NSEqualPoints([clip constrainScrollPoint: NSMakePoint(300, 300)],
                         NSMakePoint(300, 300)),
        "constrainScrollPoint: leaves an in-range point unchanged");
      PASS(NSEqualPoints([clip constrainScrollPoint: NSMakePoint(600, 600)],
                         NSMakePoint(400, 400)),
        "constrainScrollPoint: clamps a point past the maximum");
      PASS(NSEqualPoints([clip constrainScrollPoint: NSMakePoint(-50, -50)],
                         NSMakePoint(0, 0)),
        "constrainScrollPoint: clamps a negative point to zero");

      /* The returned origin is rounded to a whole pixel in window
         coordinates.  When the clip view itself does not sit on a whole
         point - a fractional scale factor puts every view there - that
         rounding must still be a fixed point: constraining the origin the
         clip view already has gives that origin back.  It used to move the
         content by up to a pixel on every call, so laying the scroll view
         out repeatedly, as resizing a table column does, scrolled the
         document away under the user. */
      {
        NSView *container = AUTORELEASE([[NSView alloc]
          initWithFrame: NSMakeRect(0, 0, 400, 400)]);
        NSClipView *offgrid = AUTORELEASE([[NSClipView alloc]
          initWithFrame: NSMakeRect(0.5, 0.5, 200, 200)]);
        NSView *offgridDoc = AUTORELEASE([[NSView alloc]
          initWithFrame: NSMakeRect(0, 0, 1000, 1000)]);
        NSPoint settled;
        int i;

        [offgrid setDocumentView: offgridDoc];
        [container addSubview: offgrid];
        [offgrid scrollToPoint: [offgrid constrainScrollPoint:
                                          NSMakePoint(40, 40)]];
        settled = [offgrid bounds].origin;
        for (i = 0; i < 10; i++)
          {
            [offgrid scrollToPoint: [offgrid constrainScrollPoint:
                                               [offgrid bounds].origin]];
          }
        PASS(NSEqualPoints([offgrid bounds].origin, settled),
          "constrainScrollPoint: of the current origin does not move it");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSClipView constrain")
  return 0;
}
