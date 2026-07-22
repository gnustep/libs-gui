#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSScrollView.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSScrollView geometry")

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

      /* With no scrollers and no border there is no decoration, so content
         and frame sizes are equal. Checked against AppKit. */
      PASS(NSEqualSizes([sv contentSize], NSMakeSize(100, 100)),
        "contentSize with no scrollers or border equals the frame size");
      PASS(NSEqualSizes([NSScrollView frameSizeForContentSize: NSMakeSize(80, 60)
                                       hasHorizontalScroller: NO
                                         hasVerticalScroller: NO
                                                  borderType: NSNoBorder],
                        NSMakeSize(80, 60)),
        "frameSizeForContentSize: is identity without decoration");
      PASS(NSEqualSizes([NSScrollView contentSizeForFrameSize: NSMakeSize(80, 60)
                                       hasHorizontalScroller: NO
                                         hasVerticalScroller: NO
                                                  borderType: NSNoBorder],
                        NSMakeSize(80, 60)),
        "contentSizeForFrameSize: is identity without decoration");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSScrollView geometry")
  DESTROY(arp);
  return 0;
}
