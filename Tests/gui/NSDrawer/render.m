#import "Testing.h"
#import "../GSRenderTest.h"
#import <AppKit/NSBox.h>
#import <AppKit/NSDrawer.h>

/* Local render exercise for NSDrawer: give it a boxed content view and render
   that content, checking it drew.  Needs a window server, so it skips cleanly
   without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSDrawer render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSDrawer *d = AUTORELEASE([[NSDrawer alloc]
        initWithContentSize: NSMakeSize(160, 120)
              preferredEdge: NSMaxXEdge]);
      NSBox *box = AUTORELEASE([[NSBox alloc]
        initWithFrame: NSMakeRect(0, 0, 160, 120)]);
      NSView *cv;
      NSSize sz;
      NSBitmapImageRep *rep;

      [box setTitle: @"Drawer"];
      [d setContentView: box];

      cv = [d contentView];
      sz = [cv bounds].size;
      rep = GSRenderView(cv);
      GSSavePNG(rep, @"nsdrawer");

      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the drawer content renders into a bitmap of its size");

      /* the box border draws around the content */
      PASS(GSRegionHasContent(rep, NSMakeRect(0, 0, sz.width, sz.height)),
        "the content view has drawn content");

      /* golden aid (local only) */
      PASS(GSMatchesGolden(rep, @"nsdrawer", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSDrawer render")
  DESTROY(arp);
  return 0;
}
