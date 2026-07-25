#import "Testing.h"
#import "../GSRenderTest.h"
#import <AppKit/NSButton.h>

/* Local render exercise for NSPanel: build a titled panel with a button in its
   content view, render the window for real, save a PNG to look at, and check
   structurally that the content drew.  Needs a window server, so it skips
   cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSPanel render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSPanel *p = AUTORELEASE([[NSPanel alloc]
        initWithContentRect: NSMakeRect(0, 0, 220, 120)
                  styleMask: NSTitledWindowMask | NSClosableWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSButton *b;
      NSView *content;
      NSSize sz;
      NSBitmapImageRep *rep;

      [p setTitle: @"Panel"];
      b = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(60, 45, 100, 30)]);
      [b setTitle: @"OK"];
      [b setBezelStyle: NSRoundedBezelStyle];
      [[p contentView] addSubview: b];

      content = [p contentView];
      sz = [content bounds].size;

      rep = GSRenderWindow(p);
      GSSavePNG(rep, @"nspanel");

      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the panel renders into a bitmap of its content size");

      /* the button sits in the middle of the content and must have drawn */
      PASS(GSRegionHasContent(rep, NSMakeRect(60, 45, 100, 30)),
        "the button area has drawn content");

      /* golden aid (local only) */
      PASS(GSMatchesGolden(rep, @"nspanel", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSPanel render")
  DESTROY(arp);
  return 0;
}
