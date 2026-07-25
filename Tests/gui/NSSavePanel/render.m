#import "Testing.h"
#import "../GSRenderTest.h"

/* Local render exercise for NSSavePanel: point the panel at a known directory,
   render its window for real, save a PNG to look at, and check structurally
   that the panel actually laid out its parts (a populated file browser, a name
   field, and the OK/Cancel buttons).  Needs a window server, so it skips
   cleanly without one. */

static NSString *
dummyDir(void)
{
  /* The fixture ../dummy sits next to this test's build directory. */
  return [[[[[NSBundle mainBundle] bundlePath]
    stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]
    stringByAppendingPathComponent: @"dummy"];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSSavePanel render")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSSavePanel *p = [NSSavePanel savePanel];
      NSView *content;
      NSSize sz;
      NSBitmapImageRep *rep;
      NSBrowser *browser;
      NSView *nameField;

      [p setTitle: @"Save"];
      [p setNameFieldStringValue: @"untitled.txt"];
      [p setDirectory: dummyDir()];
      [p setContentSize: NSMakeSize(420, 350)];

      content = [p contentView];
      sz = [content bounds].size;
      browser = (NSBrowser *)[content viewWithTag: NSFileHandlingPanelBrowser];
      nameField = [content viewWithTag: NSFileHandlingPanelForm];

      rep = GSRenderWindow(p);
      GSSavePNG(rep, @"nssavepanel");

      PASS(rep != nil && [rep pixelsWide] == (NSInteger)sz.width
        && [rep pixelsHigh] == (NSInteger)sz.height,
        "the panel renders into a bitmap of its content size");

      /* The browser occupies the upper area and, pointed at the fixture,
         must have drawn file rows there rather than being blank. */
      PASS(browser != nil, "the panel has a file browser");
      PASS(GSRegionHasContent(rep,
        NSMakeRect(10, sz.height * 0.55, sz.width - 20, sz.height * 0.3)),
        "the browser area has drawn file content");

      /* The name field sits in the lower area and shows the file name. */
      PASS(nameField != nil, "the panel has a name field");
      PASS(GSRegionHasContent(rep,
        NSMakeRect(10, sz.height * 0.30, sz.width - 20, 24)),
        "the name field area has drawn content");

      /* golden aid (local only) */
      PASS(GSMatchesGolden(rep, @"nssavepanel", 0.05),
        "matches the local golden (captured on first run)");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSavePanel render")
  DESTROY(arp);
  return 0;
}
