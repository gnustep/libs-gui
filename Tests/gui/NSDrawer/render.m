#import "Testing.h"
#import "../GSRenderTest.h"
#import <AppKit/NSDrawer.h>
#import <GNUstepGUI/GSTheme.h>

/* Render the drawer itself, including its trim.  Pixel regions, rather than
   machine-local golden images, make this usable on the CI cairo backend. */
int
main(void)
{
  START_SET("NSDrawer render")
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if (getenv("GS_REQUIRE_DRAWER_DISPLAY") == NULL
        && [[localException name] isEqual: NSInternalInconsistencyException])
      SKIP("GNUstep backend unavailable")
    else
      [localException raise];
  NS_ENDHANDLER

  /* Exercise the built-in drawing, independently of installed user themes. */
  [GSTheme setTheme: [GSTheme loadThemeNamed: @"GNUstep"]];
  {
    NSDrawer *drawer = AUTORELEASE([[NSDrawer alloc]
      initWithContentSize: NSMakeSize(160, 120) preferredEdge: NSMaxXEdge]);
    NSWindow *parent = AUTORELEASE([[NSWindow alloc]
      initWithContentRect: NSMakeRect(300, 300, 300, 200)
                styleMask: NSTitledWindowMask
                  backing: NSBackingStoreBuffered defer: NO]);
    NSRectEdge edges[] = { NSMinXEdge, NSMaxXEdge, NSMinYEdge, NSMaxYEdge };
    unsigned i;

    [parent setReleasedWhenClosed: NO];
    [drawer setParentWindow: parent];
    [parent orderFront: nil];
    for (i = 0; i < 4; i++)
      {
        NSView *content = [drawer contentView];
        NSBitmapImageRep *rep;
        NSRect frame, bounds;
        CGFloat width, height;

        [drawer openOnEdge: edges[i]];
        frame = [content frame];
        bounds = [[content superview] bounds];
        PASS(NSMinX(frame) > 0 && NSMinY(frame) > 0
          && NSMinX(frame) == NSMaxX(bounds) - NSMaxX(frame)
          && NSMinY(frame) == NSMaxY(bounds) - NSMaxY(frame),
          "drawer content has even, unclipped insets");
        rep = GSRenderWindow([content window]);
        width = [rep pixelsWide];
        height = [rep pixelsHigh];
        GSSavePNG(rep, [NSString stringWithFormat: @"nsdrawer-edge-%u", i]);
        PASS(rep != nil && width == bounds.size.width
          && height == bounds.size.height, "the entire drawer renders");
        PASS(GSRegionMinBrightness(rep, NSMakeRect(0, 0, 1, height))
          < GSRegionMinBrightness(rep, NSMakeRect(width / 2, height / 2, 1, 1)),
          "the thin drawer border is distinct from its background");
        [drawer close];
      }
    [parent orderOut: nil];
  }
  END_SET("NSDrawer render")
  return 0;
}

