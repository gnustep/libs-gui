#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSView.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSScrollView structure")

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
      NSView *doc = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 500, 500)]);
      [sv setDocumentView: doc];

      /* Document / clip-view structure. Checked against AppKit. */
      PASS([sv documentView] == doc, "setDocumentView: round-trips");
      PASS([[sv contentView] isKindOfClass: [NSClipView class]],
        "contentView is an NSClipView");
      PASS([doc superview] == [sv contentView],
        "the document view's superview is the clip view");
      PASS([doc enclosingScrollView] == sv,
        "the document view's enclosingScrollView is the scroll view");

      [sv setHasHorizontalScroller: YES];
      PASS([sv hasHorizontalScroller], "setHasHorizontalScroller: round-trips");
      [sv setHasVerticalScroller: YES];
      PASS([sv hasVerticalScroller], "setHasVerticalScroller: round-trips");
      [sv setBorderType: NSBezelBorder];
      PASS([sv borderType] == NSBezelBorder, "setBorderType: round-trips");
      [sv setLineScroll: 12.0];
      PASS([sv lineScroll] == 12.0, "setLineScroll: round-trips");
      [sv setScrollsDynamically: NO];
      PASS([sv scrollsDynamically] == NO, "setScrollsDynamically: round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSScrollView structure")
  DESTROY(arp);
  return 0;
}
