#import "Testing.h"
#import <AppKit/AppKit.h>
#include <math.h>

int
main(int argc, const char **argv)
{
  START_SET("NSPopover rendering")

  NSWindow *window;
  NSView *content;
  NSViewController *controller;
  NSPopover *popover;
  NSRectEdge edges[] = {NSMinXEdge, NSMaxXEdge, NSMinYEdge, NSMaxYEdge};
  NSUInteger i;

  [NSApplication sharedApplication];
  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(200, 200, 400, 300)
                                      styleMask: NSBorderlessWindowMask
                                        backing: NSBackingStoreBuffered
                                          defer: NO];
  [window setReleasedWhenClosed: NO];
  content = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 120, 80)]);
  controller = AUTORELEASE([[NSViewController alloc] init]);
  [controller setView: content];
  popover = AUTORELEASE([[NSPopover alloc] init]);
  [popover setContentViewController: controller];

  for (i = 0; i < 4; i++)
    {
      NSView *decoration;
      NSImage *image;
      NSBitmapImageRep *rep;
      NSRect bounds;
      NSColor *corner, *border, *body;
      NSInteger x, y;

      [popover showRelativeToRect: NSMakeRect(150, 100, 40, 30)
                          ofView: [window contentView]
                   preferredEdge: edges[i]];
      decoration = [content superview];
      bounds = [decoration bounds];
      image = [[NSImage alloc] initWithSize: bounds.size];
      [image lockFocus];
      /* Start with opaque pixels to verify that drawing clears old content. */
      [[NSColor redColor] set];
      NSRectFill(bounds);
      [decoration drawRect: bounds];
      [image unlockFocus];
      rep = [NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]];
      x = (edges[i] == NSMinXEdge) ? NSWidth(bounds) - 2 : 1;
      y = (edges[i] == NSMaxYEdge) ? NSHeight(bounds) - 2 : 1;
      corner = [rep colorAtX: x y: y];
      PASS([corner alphaComponent] < 0.01,
        "pixels beside the arrow are transparent on every edge");
      x = (edges[i] == NSMaxXEdge) ? NSWidth(bounds) - 1 : 0;
      y = NSHeight(bounds) / 2;
      if (edges[i] == NSMinXEdge || edges[i] == NSMaxXEdge)
        {
          x = NSWidth(bounds) / 2;
          y = 0;
        }
      border = [[rep colorAtX: x y: y]
        colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      body = [[rep colorAtX: NSWidth(bounds) / 2 y: NSHeight(bounds) / 2]
        colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
      PASS([border alphaComponent] > 0.99
        && fabs([border redComponent] - [body redComponent]) > 0.1,
        "the popover has a visible opaque outline");
      PASS(NSEqualSizes([content frame].size, NSMakeSize(120, 80)),
        "the border preserves the controller's requested content size");
      RELEASE(image);
      [popover close];
    }
  [window close];
  RELEASE(window);

  END_SET("NSPopover rendering")
  return 0;
}

