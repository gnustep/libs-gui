#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSView.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSScrollView scroll")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSScrollView *sv = AUTORELEASE([[NSScrollView alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);
      [sv setHasHorizontalScroller: NO];
      [sv setHasVerticalScroller: NO];
      [sv setBorderType: NSNoBorder];
      NSView *doc = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 500, 500)]);
      [sv setDocumentView: doc];

      /* Scrolling a 500x500 document in a 100x100 clip view to (300,300,50,50)
         moves the visible rectangle. Checked against AppKit. */
      [doc scrollRectToVisible: NSMakeRect(300, 300, 50, 50)];
      PASS(NSEqualRects([sv documentVisibleRect], NSMakeRect(250, 250, 100, 100)),
        "documentVisibleRect reflects a scroll");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSScrollView scroll")
  DESTROY(arp);
  return 0;
}
