#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSView.h>

/* Lay out an autohiding scroll view whose document is a given size and
   return whether each scroller ended up visible.  With the pre-#234 code a
   document sized so that showing one scroller forces the other on (and vice
   versa) makes -reflectScrolledClipView: and -tile recurse without bound and
   the process crashes, so simply returning from here is the regression check. */
static void
layoutScrollView(NSSize frame, NSSize document, BOOL *hasVert, BOOL *hasHoriz)
{
  NSScrollView *sv = AUTORELEASE([[NSScrollView alloc]
    initWithFrame: NSMakeRect(0, 0, frame.width, frame.height)]);
  NSView *doc = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, document.width, document.height)]);

  [sv setBorderType: NSNoBorder];
  [sv setDocumentView: doc];
  [sv setHasVerticalScroller: YES];
  [sv setHasHorizontalScroller: NO];
  [sv setAutohidesScrollers: YES];

  [doc setFrameSize: document];
  [sv reflectScrolledClipView: [sv contentView]];
  [sv setFrame: NSMakeRect(0, 0, frame.width, frame.height)];
  [sv tile];

  *hasVert = [sv hasVerticalScroller];
  *hasHoriz = [sv hasHorizontalScroller];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSScrollView autohidesScrollers")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      BOOL hasVert, hasHoriz;
      NSSize frame = NSMakeSize(800, 600);

      /* The size that used to trigger the runaway recursion (bug #234): the
         document is within a scroller width of the frame on both axes, so the
         two scrollers keep flipping each other's visibility.  Reaching the
         next line at all means the recursion is now bounded. */
      layoutScrollView(frame, NSMakeSize(792, 595), &hasVert, &hasHoriz);
      PASS(1, "autohidesScrollers does not recurse for a critical document size");

      /* A document that fits needs neither scroller. */
      layoutScrollView(frame, NSMakeSize(400, 300), &hasVert, &hasHoriz);
      PASS(hasVert == NO && hasHoriz == NO,
        "no scrollers are shown when the document fits");

      /* A document taller than the frame needs a vertical scroller; that
         scroller then narrows the clip view enough that the horizontal
         scroller is needed too. */
      layoutScrollView(frame, NSMakeSize(792, 640), &hasVert, &hasHoriz);
      PASS(hasVert == YES && hasHoriz == YES,
        "a scroller that narrows the clip view brings in the other scroller");

      /* Symmetrically for a document wider than the frame. */
      layoutScrollView(frame, NSMakeSize(840, 595), &hasVert, &hasHoriz);
      PASS(hasVert == YES && hasHoriz == YES,
        "a wide document brings in both scrollers");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSScrollView autohidesScrollers")
  DESTROY(arp);
  return 0;
}
