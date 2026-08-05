/* NSSplitView posts the will- and did-resize-subviews notifications around
   -adjustSubviews when it has subviews, with the split view as the object, and
   posts nothing when it has no subviews.  structure.m covers the subview and
   divider geometry; this covers the resize notifications.  The split view uses
   the theme and font backend, so the set is skipped when the backend is
   unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSView.h>

@interface Recorder : NSObject
{
@public
  int willCount;
  int didCount;
  id willObject;
}
- (void) willResize: (NSNotification *)n;
- (void) didResize: (NSNotification *)n;
@end

@implementation Recorder
- (void) willResize: (NSNotification *)n
{
  willCount++;
  willObject = [n object];
}
- (void) didResize: (NSNotification *)n
{
  didCount++;
}
@end

static void
observe(NSNotificationCenter *nc, Recorder *r, NSSplitView *sv)
{
  [nc addObserver: r
         selector: @selector(willResize:)
             name: NSSplitViewWillResizeSubviewsNotification
           object: sv];
  [nc addObserver: r
         selector: @selector(didResize:)
             name: NSSplitViewDidResizeSubviewsNotification
           object: sv];
}

int
main(int argc, char **argv)
{
  Recorder *r, *r2;
  NSSplitView *sv, *empty;
  NSNotificationCenter *nc;

  START_SET("NSSplitView resize notification")

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
      nc = [NSNotificationCenter defaultCenter];

      /* A split view with subviews posts both notifications on adjustSubviews. */
      r = AUTORELEASE([[Recorder alloc] init]);
      sv = AUTORELEASE([[NSSplitView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      [sv addSubview: AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)])];
      [sv addSubview: AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 100, 200, 100)])];
      observe(nc, r, sv);

      [sv adjustSubviews];
      PASS(r->willCount == 1 && r->didCount == 1,
        "adjustSubviews posts the will and did resize notifications");
      PASS(r->willObject == sv, "the notification object is the split view");

      /* A split view with no subviews posts nothing. */
      r2 = AUTORELEASE([[Recorder alloc] init]);
      empty = AUTORELEASE([[NSSplitView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      observe(nc, r2, empty);

      [empty adjustSubviews];
      PASS(r2->willCount == 0 && r2->didCount == 0,
        "adjustSubviews on an empty split view posts nothing");

      [nc removeObserver: r];
      [nc removeObserver: r2];
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

  END_SET("NSSplitView resize notification")

  return 0;
}
