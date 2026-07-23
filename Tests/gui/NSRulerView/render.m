#import "Testing.h"
#import "GSRenderTest.h"
#import <AppKit/NSView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSRulerView.h>

/* Local render exercise for NSRulerView: put a ruler on a scroll view and
   render the scroll view (which draws the ruler in its own context, as it
   depends on the scroll view for its coordinates).  Needs a window server, so
   it skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSRulerView render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSScrollView *sv = AUTORELEASE([[NSScrollView alloc]
        initWithFrame: NSMakeRect(0, 0, 300, 200)]);
      NSView *doc = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 600, 400)]);
      NSRulerView *ruler;
      NSSize sz;
      NSBitmapImageRep *rep;

      [sv setDocumentView: doc];
      [sv setHasHorizontalRuler: YES];
      [sv setRulersVisible: YES];
      ruler = [sv horizontalRulerView];

      sz = [sv bounds].size;
      rep = GSRenderView(sv);
      GSSavePNG(rep, @"nsrulerview");

      PASS(ruler != nil && [ruler bounds].size.width > 0,
        "the scroll view has a horizontal ruler");
      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the scroll view renders into a bitmap of its size");

      /* the ruler and the scroll view frame draw content */
      PASS(GSRegionHasContent(rep, NSMakeRect(0, 0, sz.width, sz.height)),
        "the ruler and scroll view have drawn content");

      /* golden aid (local only) */
      PASS(GSMatchesGolden(rep, @"nsrulerview", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSRulerView render")
  DESTROY(arp);
  return 0;
}
