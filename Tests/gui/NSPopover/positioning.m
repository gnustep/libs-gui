#import "Testing.h"
#import <AppKit/AppKit.h>

@interface FlippedPopoverAnchor : NSView

@end

@implementation FlippedPopoverAnchor

- (BOOL) isFlipped
{
  return YES;
}

@end

int
main(int argc, const char **argv)
{
  START_SET("NSPopover positioning")

  NSWindow *window;
  NSView *container;
  NSView *anchor;
  NSView *content;
  NSViewController *controller;
  NSPopover *popover;
  NSRect rect = NSMakeRect(7, 11, 40, 30);
  NSRect target;
  NSRect frame;
  NSRectEdge edges[] = {NSMinXEdge, NSMaxXEdge, NSMinYEdge, NSMaxYEdge};
  NSUInteger flipped, i;

  /* These tests require a window server; property-only tests do not. */
  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name]
      isEqualToString: @"NSWindowServerCommunicationException"])
      {
        SKIP("No display available for NSPopover window tests")
      }
    else
      [localException raise];
  NS_ENDHANDLER
  window = [[NSWindow alloc] initWithContentRect: NSMakeRect(300, 300, 400, 300)
                                      styleMask: NSBorderlessWindowMask
                                        backing: NSBackingStoreBuffered
                                          defer: NO];
  [window setReleasedWhenClosed: NO];
  container = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(31, 43, 250, 200)]);
  [[window contentView] addSubview: container];
  content = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(17, 23, 90, 60)]);
  controller = AUTORELEASE([[NSViewController alloc] init]);
  [controller setView: content];
  popover = AUTORELEASE([[NSPopover alloc] init]);
  [popover setContentViewController: controller];
  [popover setContentSize: NSMakeSize(120, 80)];

  for (flipped = 0; flipped < 2; flipped++)
    {
      anchor = AUTORELEASE([[(flipped ? [FlippedPopoverAnchor class]
        : [NSView class]) alloc] initWithFrame: NSMakeRect(29, 37, 100, 90)]);
      [container addSubview: anchor];
      target = [anchor convertRect: rect toView: nil];
      target = [window convertRectToScreen: target];
      for (i = 0; i < 4; i++)
        {
          NSRectEdge edge = edges[i];
          BOOL correct = NO;

          [popover showRelativeToRect: rect ofView: anchor preferredEdge: edge];
          frame = [[content window] frame];
          if (flipped && edge == NSMinYEdge)
            edge = NSMaxYEdge;
          else if (flipped && edge == NSMaxYEdge)
            edge = NSMinYEdge;
          switch (edge)
            {
              case NSMinXEdge:
                correct = NSMaxX(frame) == NSMinX(target)
                  && NSMidY(frame) == NSMidY(target);
                break;
              case NSMaxXEdge:
                correct = NSMinX(frame) == NSMaxX(target)
                  && NSMidY(frame) == NSMidY(target);
                break;
              case NSMinYEdge:
                correct = NSMaxY(frame) == NSMinY(target)
                  && NSMidX(frame) == NSMidX(target);
                break;
              case NSMaxYEdge:
                correct = NSMinY(frame) == NSMaxY(target)
                  && NSMidX(frame) == NSMidX(target);
                break;
            }
          PASS(correct, "the arrow tip meets the requested edge in screen coordinates");
          PASS(NSEqualSizes([content frame].size, NSMakeSize(120, 80)),
            "arrow space does not consume the requested content size");
          PASS(NSContainsRect([[content superview] bounds], [content frame]),
            "the content stays inside the decorated panel");
          PASS([[content window] isOpaque] == NO,
            "the arrow panel allows transparent corners");
          [popover close];
          PASS(![popover isShown], "closing allows safe reuse of the popover");
        }
      [popover showRelativeToRect: NSZeroRect ofView: anchor
                   preferredEdge: NSMaxXEdge];
      PASS(NSEqualRects([popover positioningRect], [anchor bounds]),
        "an empty positioning rectangle uses the anchor bounds");
      [popover performClose: nil];
      PASS(![popover isShown], "performClose works without a delegate");
      [anchor removeFromSuperview];
    }
  [window close];
  RELEASE(window);

  END_SET("NSPopover positioning")
  return 0;
}

