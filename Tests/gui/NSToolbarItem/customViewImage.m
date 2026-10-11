#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSToolbarItem.h>

@interface NSToolbarItem (Private)
- (void) _layout;
@end

int
main(int argc, char **argv)
{
  NSToolbarItem *item;
  NSButton *view;
  NSImage *image;

  START_SET("NSToolbarItem custom view image")

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

  image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(24, 24)]);
  view = AUTORELEASE([[NSButton alloc]
    initWithFrame: NSMakeRect(0, 0, 32, 32)]);
  [view setImage: image];

  item = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"item"]);
  [item setView: view];
  PASS([view image] == image, "the view keeps the image it was given");
  PASS([item image] == nil, "an item with a custom view has no image of its own");

  NS_DURING
  {
    [item _layout];
  }
  NS_HANDLER
  {
    SKIP("laying the item out needs a working backend")
  }
  NS_ENDHANDLER

  PASS([view image] == image,
       "laying the item out leaves the view's image alone");

  END_SET("NSToolbarItem custom view image")

  return 0;
}
