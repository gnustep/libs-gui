#import "Testing.h"
#import "GSRenderTest.h"
#import <AppKit/NSViewController.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSTabViewController.h>

/* Local render exercise for NSTabViewController: give it a tab view with two
   labelled tabs, render it for real, save a PNG to look at, and check the tab
   bar drew.  Needs a window server, so it skips cleanly without one. */

static NSTabViewItem *
labelledItem(NSString *ident, NSString *label)
{
  NSTabViewItem *item = AUTORELEASE([[NSTabViewItem alloc]
    initWithIdentifier: ident]);
  NSViewController *vc = AUTORELEASE([[NSViewController alloc] init]);
  [vc setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 200, 120)])];
  [item setViewController: vc];
  [item setLabel: label];
  return item;
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSTabViewController render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSTabViewController *tc = AUTORELEASE([[NSTabViewController alloc] init]);
      NSTabView *tv = AUTORELEASE([[NSTabView alloc]
        initWithFrame: NSMakeRect(0, 0, 240, 160)]);
      NSSize sz;
      NSBitmapImageRep *rep;

      [tc setTabView: tv];
      [tc addTabViewItem: labelledItem(@"one", @"One")];
      [tc addTabViewItem: labelledItem(@"two", @"Two")];

      sz = [tv bounds].size;
      rep = GSRenderView(tv);
      GSSavePNG(rep, @"nstabviewcontroller");

      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the tab view renders into a bitmap of its size");

      /* the tab bar with the two labels sits across the top */
      PASS(GSRegionHasContent(rep,
        NSMakeRect(0, sz.height - 24, sz.width, 24)),
        "the tab bar area has drawn content");

      /* golden aid (local only) */
      PASS(GSMatchesGolden(rep, @"nstabviewcontroller", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTabViewController render")
  DESTROY(arp);
  return 0;
}
