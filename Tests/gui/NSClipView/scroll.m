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
  START_SET("NSClipView scroll")

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

      /* scrollToPoint: moves the visible rectangle. Checked against AppKit. */
      [clip scrollToPoint: NSMakePoint(200, 200)];
      PASS(NSEqualRects([clip documentVisibleRect], NSMakeRect(200, 200, 100, 100)),
        "scrollToPoint: moves the visible rectangle");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSClipView scroll")
  DESTROY(arp);
  return 0;
}
