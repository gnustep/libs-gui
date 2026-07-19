#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSView.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
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
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSClipView constrain")
  DESTROY(arp);
  return 0;
}
