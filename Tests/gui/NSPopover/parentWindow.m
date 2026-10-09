#import "Testing.h"
#import <AppKit/AppKit.h>

int
main(int argc, const char **argv)
{
  START_SET("NSPopover parent window")

  NSWindow *first;
  NSWindow *second;
  NSWindow *panel;
  NSPopover *popover;
  NSViewController *controller;

  [NSApplication sharedApplication];
  first = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 300, 200)
                                    styleMask: NSTitledWindowMask
                                      backing: NSBackingStoreBuffered
                                        defer: NO];
  second = [[NSWindow alloc] initWithContentRect: NSMakeRect(400, 0, 300, 200)
                                     styleMask: NSTitledWindowMask
                                       backing: NSBackingStoreBuffered
                                         defer: NO];
  [first setReleasedWhenClosed: NO];
  [second setReleasedWhenClosed: NO];
  controller = [[NSViewController alloc] init];
  [controller setView: AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 80)])];
  popover = [[NSPopover alloc] init];
  [popover setContentViewController: controller];

  [popover showRelativeToRect: NSZeroRect
                      ofView: [first contentView]
               preferredEdge: NSMaxYEdge];
  panel = [[controller view] window];
  PASS([panel parentWindow] == first
    && [[first childWindows] containsObject: panel],
    "the popover is a child of the positioning view's window");

  [popover showRelativeToRect: NSZeroRect
                      ofView: [second contentView]
               preferredEdge: NSMaxYEdge];
  PASS([panel parentWindow] == second
    && [[second childWindows] containsObject: panel]
    && [[first childWindows] count] == 0,
    "showing in another window reparents the popover");

  [popover close];
  PASS([[second childWindows] count] == 0 && ![popover isShown],
    "closing removes the popover from its parent's children");
  [popover showRelativeToRect: NSZeroRect
                      ofView: [first contentView]
               preferredEdge: NSMaxYEdge];
  panel = [[controller view] window];
  PASS([panel parentWindow] == first && [popover isShown],
    "a closed popover can be shown as a child again");
  [panel orderOut: nil];
  PASS([[first childWindows] count] == 0 && ![popover isShown],
    "ordering the panel out also removes the child relationship");

  [popover release];
  [controller release];
  [first close];
  [second close];
  [first release];
  [second release];

  END_SET("NSPopover parent window")
  return 0;
}
