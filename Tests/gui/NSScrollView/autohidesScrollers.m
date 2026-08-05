#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSView.h>

/* Lay out an autohiding scroll view whose document is a given size, with each
   axis configured to want a scroller or not, and return whether each scroller
   ended up shown.  With the pre-#234 code a document sized so that showing one
   scroller forces the other (and vice versa) makes -reflectScrolledClipView:
   and -tile recurse without bound and the process crashes, so simply returning
   from here is that regression check.  Autohiding only ever shows a scroller on
   an axis the client asked to have one (#236): an axis set to NO stays without
   a scroller even when its content overflows. */
static void
layoutScrollView(NSSize frame, NSSize document, BOOL wantHoriz, BOOL wantVert,
                 BOOL *hasVert, BOOL *hasHoriz)
{
  NSScrollView *sv = AUTORELEASE([[NSScrollView alloc]
    initWithFrame: NSMakeRect(0, 0, frame.width, frame.height)]);
  NSView *doc = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, document.width, document.height)]);

  [sv setBorderType: NSNoBorder];
  [sv setDocumentView: doc];
  [sv setHasVerticalScroller: wantVert];
  [sv setHasHorizontalScroller: wantHoriz];
  [sv setAutohidesScrollers: YES];

  [doc setFrameSize: document];
  [sv reflectScrolledClipView: [sv contentView]];
  [sv setFrame: NSMakeRect(0, 0, frame.width, frame.height)];
  [sv tile];

  /* -hasVerticalScroller/-hasHorizontalScroller report the configured setting,
     not the current autohidden visibility, so check whether each scroller is
     actually shown by whether it is in the view hierarchy. */
  *hasVert = ([[sv verticalScroller] superview] != nil);
  *hasHoriz = ([[sv horizontalScroller] superview] != nil);
}

int
main(int argc, const char **argv)
{
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
         two scrollers keep flipping each other's visibility.  Reaching the next
         line at all means the recursion is now bounded. */
      layoutScrollView(frame, NSMakeSize(792, 595), YES, YES, &hasVert, &hasHoriz);
      PASS(1, "autohidesScrollers does not recurse for a critical document size");

      /* A document that fits needs neither scroller. */
      layoutScrollView(frame, NSMakeSize(400, 300), YES, YES, &hasVert, &hasHoriz);
      PASS(hasVert == NO && hasHoriz == NO,
        "no scrollers are shown when the document fits");

      /* The getter reports the configured setting, not the autohidden
         visibility, as on macOS. */
      {
        NSScrollView *sv = AUTORELEASE([[NSScrollView alloc]
          initWithFrame: NSMakeRect(0, 0, frame.width, frame.height)]);
        NSView *doc = AUTORELEASE([[NSView alloc]
          initWithFrame: NSMakeRect(0, 0, 400, 300)]);
        [sv setBorderType: NSNoBorder];
        [sv setDocumentView: doc];
        [sv setHasVerticalScroller: YES];
        [sv setAutohidesScrollers: YES];
        [sv reflectScrolledClipView: [sv contentView]];
        [sv tile];
        PASS([sv hasVerticalScroller] == YES,
          "hasVerticalScroller reports the configured value when autohidden");
        PASS([[sv verticalScroller] superview] == nil,
          "the configured scroller is hidden for a document that fits");
      }

      /* A document taller than the frame needs a vertical scroller; that
         scroller then narrows the clip view enough that the horizontal scroller
         is needed too. */
      layoutScrollView(frame, NSMakeSize(792, 640), YES, YES, &hasVert, &hasHoriz);
      PASS(hasVert == YES && hasHoriz == YES,
        "a scroller that narrows the clip view brings in the other scroller");

      /* Symmetrically for a document wider than the frame. */
      layoutScrollView(frame, NSMakeSize(840, 595), YES, YES, &hasVert, &hasHoriz);
      PASS(hasVert == YES && hasHoriz == YES,
        "a wide document brings in both scrollers");

      /* #236: a horizontal scroller the client did not ask for is not shown
         even when the document is wider than the frame. */
      layoutScrollView(frame, NSMakeSize(900, 500), NO, YES, &hasVert, &hasHoriz);
      PASS(hasHoriz == NO,
        "a disabled horizontal scroller stays hidden for a wide document");
      PASS(hasVert == NO,
        "the vertical scroller is not needed once the horizontal one cannot show");

      /* #236: symmetrically, a disabled vertical scroller stays hidden for a
         tall document. */
      layoutScrollView(frame, NSMakeSize(500, 900), YES, NO, &hasVert, &hasHoriz);
      PASS(hasVert == NO,
        "a disabled vertical scroller stays hidden for a tall document");
      PASS(hasHoriz == NO,
        "the horizontal scroller is not needed once the vertical one cannot show");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSScrollView autohidesScrollers")
  return 0;
}
