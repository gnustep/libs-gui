/* The application's dock tile is owned by the application, so that whatever is
 * handed the tile can find its way back.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDockTile.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSView.h>

@interface NSApplication (MiniwindowDrawingTest)
- (NSDockTile *) _dockTileIfExists;
@end

static void drawMiniwindow(void)
{
  NSView *view = AUTORELEASE([[NSClassFromString(@"NSMiniWindowView") alloc]
    initWithFrame: NSMakeRect(0, 0, 64, 64)]);
  NSImage *image = AUTORELEASE([[NSImage alloc]
    initWithSize: NSMakeSize(64, 64)]);

  [image lockFocus];
  @try
    {
      [view drawRect: [view bounds]];
    }
  @finally
    {
      [image unlockFocus];
    }
}

int
main(int argc, char **argv)
{
  START_SET("the dock tile owner")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSDockTile	*tile;

    /* Miniwindows consult the existing tile while drawing.  They must
     * neither send an unimplemented selector nor create a tile recursively. */
    drawMiniwindow();
    PASS([NSApp _dockTileIfExists] == nil,
      "miniwindow drawing does not create a dock tile");

    tile = [NSApp dockTile];
    [tile setBadgeLabel: @"7"];
    drawMiniwindow();
    PASS([NSApp _dockTileIfExists] == tile,
      "miniwindow drawing uses the existing badged dock tile");
    PASS([tile owner] == NSApp,
      "the application dock tile is owned by the application");

    /* and the owner is still whatever it is set to */
    [tile setOwner: nil];
    PASS([tile owner] == nil, "the owner round-trips");
    [tile setOwner: NSApp];
    PASS([tile owner] == NSApp, "the owner reads back");
  }

  END_SET("the dock tile owner")

  return 0;
}
