#import "Testing.h"
#import <AppKit/AppKit.h>

static void
ProcessWindowEvents(void)
{
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow: 0.2];
  NSEvent *event;

  while ((event = [NSApp nextEventMatchingMask: NSAnyEventMask
                                   untilDate: deadline
                                      inMode: NSDefaultRunLoopMode
                                     dequeue: YES]) != nil)
    [NSApp sendEvent: event];
}

int
main(int argc, const char **argv)
{
  START_SET("NSPopover parent window")

  NSWindow *first, *second, *panel;
  NSView *content;
  NSViewController *controller;
  NSPopover *popover;
  NSRect before, after;

  [NSApplication sharedApplication];
  first = [[NSWindow alloc] initWithContentRect: NSMakeRect(200, 200, 400, 300)
                                    styleMask: NSBorderlessWindowMask
                                      backing: NSBackingStoreBuffered
                                        defer: NO];
  second = [[NSWindow alloc] initWithContentRect: NSMakeRect(300, 300, 400, 300)
                                     styleMask: NSBorderlessWindowMask
                                       backing: NSBackingStoreBuffered
                                         defer: NO];
  [first setReleasedWhenClosed: NO];
  [second setReleasedWhenClosed: NO];
  [first orderFront: nil];
  [second orderFront: nil];
  content = AUTORELEASE([[NSView alloc]
    initWithFrame: NSMakeRect(0, 0, 120, 80)]);
  controller = AUTORELEASE([[NSViewController alloc] init]);
  [controller setView: content];
  popover = [[NSPopover alloc] init];
  [popover setContentViewController: controller];

  [popover showRelativeToRect: NSMakeRect(100, 100, 40, 30)
                      ofView: [first contentView] preferredEdge: NSMaxYEdge];
  panel = [content window];
  PASS([panel parentWindow] == first
    && [[first childWindows] containsObject: panel],
    "the popover is attached to its positioning window");
  ProcessWindowEvents();
  before = [panel frame];
  [first setFrameOrigin: NSMakePoint(225, 235)];
  ProcessWindowEvents();
  after = [panel frame];
  PASS(after.origin.x == before.origin.x + 25
    && after.origin.y == before.origin.y + 35,
    "moving the parent moves the popover by the same amount");

  [popover showRelativeToRect: NSMakeRect(100, 100, 40, 30)
                      ofView: [second contentView] preferredEdge: NSMaxYEdge];
  PASS([panel parentWindow] == second
    && ![[first childWindows] containsObject: panel]
    && [[second childWindows] containsObject: panel],
    "showing in another window removes the previous attachment");
  [popover close];
  PASS([panel parentWindow] == nil
    && ![[second childWindows] containsObject: panel],
    "closing detaches the popover");

  [popover showRelativeToRect: NSMakeRect(100, 100, 40, 30)
                      ofView: [first contentView] preferredEdge: NSMaxYEdge];
  PASS([panel parentWindow] == first,
    "reopening attaches the popover again");
  [popover showRelativeToRect: NSMakeRect(110, 110, 40, 30)
                      ofView: [first contentView] preferredEdge: NSMaxYEdge];
  PASS([[first childWindows] count] == 1,
    "repeated presentation does not duplicate the child");
  RETAIN(panel);
  RELEASE(popover);
  PASS([panel parentWindow] == nil && [[first childWindows] count] == 0,
    "destroying a shown popover removes its parent attachment");
  RELEASE(panel);
  [first close];
  [second close];
  RELEASE(first);
  RELEASE(second);

  END_SET("NSPopover parent window")
  return 0;
}

