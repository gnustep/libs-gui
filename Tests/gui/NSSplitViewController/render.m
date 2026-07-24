#import "Testing.h"
#import "../GSRenderTest.h"
#import <AppKit/NSBox.h>
#import <AppKit/NSSplitView.h>
#import <AppKit/NSSplitViewController.h>

/* Local render exercise for NSSplitViewController: give it a split view with
   two boxed panes, render it for real, save a PNG to look at, and check the
   panes drew.  Needs a window server, so it skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSplitViewController render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSplitViewController *svc = AUTORELEASE([[NSSplitViewController alloc] init]);
      NSSplitView *sv = AUTORELEASE([[NSSplitView alloc]
        initWithFrame: NSMakeRect(0, 0, 240, 160)]);
      NSBox *left = AUTORELEASE([[NSBox alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 160)]);
      NSBox *right = AUTORELEASE([[NSBox alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 160)]);
      NSSize sz;
      NSBitmapImageRep *rep;

      [sv addSubview: left];
      [sv addSubview: right];
      [svc setSplitView: sv];

      sz = [[svc splitView] bounds].size;
      rep = GSRenderView([svc splitView]);
      GSSavePNG(rep, @"nssplitviewcontroller");

      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the split view renders into a bitmap of its size");

      /* the left boxed pane draws its border on the left side */
      PASS(GSRegionHasContent(rep, NSMakeRect(0, 0, sz.width * 0.45, sz.height)),
        "the left pane has drawn content");

      /* golden aid (local only) */
      PASS(GSMatchesGolden(rep, @"nssplitviewcontroller", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSplitViewController render")
  DESTROY(arp);
  return 0;
}
