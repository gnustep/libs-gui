#import "Testing.h"
#import "GSRenderTest.h"

/* Local render exercise for NSOpenPanel: point it at a known directory, render
   its window, and check structurally that it laid out a populated file browser
   and the OK/Cancel area.  Needs a window server, so it skips without one. */

static NSString *
dummyDir(void)
{
  return [[[[[NSBundle mainBundle] bundlePath]
    stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]
    stringByAppendingPathComponent: @"dummy"];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSOpenPanel render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSOpenPanel *p = [NSOpenPanel openPanel];
      NSView *content;
      NSSize sz;
      NSBitmapImageRep *rep;

      [p setTitle: @"Open"];
      [p setDirectory: dummyDir()];
      [p setContentSize: NSMakeSize(420, 350)];

      content = [p contentView];
      sz = [content bounds].size;

      rep = GSRenderWindow(p);
      GSSavePNG(rep, @"nsopenpanel");

      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the panel renders into a bitmap of its content size");
      PASS([content viewWithTag: NSFileHandlingPanelBrowser] != nil,
        "the panel has a file browser");
      PASS(GSRegionHasContent(rep,
        NSMakeRect(10, sz.height * 0.55, sz.width - 20, sz.height * 0.3)),
        "the browser area has drawn file content");
      PASS(GSRegionHasContent(rep, NSMakeRect(10, 4, sz.width - 20, 30)),
        "the button area at the bottom has drawn content");
      PASS(GSMatchesGolden(rep, @"nsopenpanel", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOpenPanel render")
  DESTROY(arp);
  return 0;
}
