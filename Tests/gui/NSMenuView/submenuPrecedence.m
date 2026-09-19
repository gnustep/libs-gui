/* Menu tracking must hand the pointer to the most deeply nested open menu
 * under it.  A submenu that has no room on the right opens on the left,
 * where it covers the menus it came from; tracking used to give the pointer
 * to those covered menus, so such a submenu could not be used.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSWindow.h>
#include <GNUstepGUI/GSDisplayServer.h>
#include <objc/runtime.h>

@interface NSMenuView (TrackingPrivate)
- (BOOL) _trackWithEvent: (NSEvent *)event
        startingMenuView: (NSMenuView *)mainWindowMenuView;
@end

/* Only the menu view the test starts tracking in runs the real loop; any
 * menu it hands the pointer to is recorded and returns at once, so the
 * test sees the hand-over without a nested tracking loop. */
static IMP originalTrack;
static NSMenuView *startView;
static NSMenuView *handedTo;

static BOOL
recordingTrack(id self, SEL _cmd, NSEvent *event, NSMenuView *main)
{
  if (self != startView)
    {
      if (handedTo == nil)
        {
          handedTo = self;
        }
      return NO;
    }
  return ((BOOL (*)(id, SEL, NSEvent *, NSMenuView *))originalTrack)
    (self, _cmd, event, main);
}

static NSMenu *
menuWithSubmenu(NSString *title, NSMenu *submenu)
{
  NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: title]);
  id <NSMenuItem> item;

  item = [menu addItemWithTitle: @"First item with a long title"
                         action: NULL
                  keyEquivalent: @""];
  [menu addItemWithTitle: @"Second item with a long title"
                  action: NULL
           keyEquivalent: @""];
  [menu addItemWithTitle: @"Third item with a long title"
                  action: NULL
           keyEquivalent: @""];
  if (submenu != nil)
    {
      [menu setSubmenu: submenu forItem: item];
    }
  return menu;
}

static void
postMouseUp(void)
{
  NSEvent *up = [NSEvent mouseEventWithType: NSLeftMouseUp
                                   location: NSZeroPoint
                              modifierFlags: 0
                                  timestamp: 0
                               windowNumber: 0
                                    context: nil
                                eventNumber: 0
                                 clickCount: 1
                                   pressure: 0];

  /* The loop only finishes on the second release: the first one merely
   * arms it. */
  [NSApp postEvent: up atStart: NO];
  [NSApp postEvent: up atStart: NO];
}

static void
drainEvents(void)
{
  NSEvent *e;

  do
    {
      e = [NSApp nextEventMatchingMask: NSAnyEventMask
                             untilDate: [NSDate dateWithTimeIntervalSinceNow: 0.2]
                                inMode: NSDefaultRunLoopMode
                               dequeue: YES];
    }
  while (e != nil);
}

/* Starts tracking in the middle menu with the pointer at a screen point and
 * returns the menu view tracking was handed to. */
static NSMenuView *
trackFrom(NSMenuView *middle, NSPoint screenPoint)
{
  NSEvent *down;

  [GSCurrentServer() setMouseLocation: screenPoint onScreen: 0];
  drainEvents();
  down = [NSEvent mouseEventWithType: NSLeftMouseDown
                            location: NSZeroPoint
                       modifierFlags: 0
                           timestamp: 0
                        windowNumber: [[middle window] windowNumber]
                             context: nil
                         eventNumber: 0
                          clickCount: 1
                            pressure: 0];
  postMouseUp();
  handedTo = nil;
  startView = middle;
  [middle _trackWithEvent: down startingMenuView: nil];
  drainEvents();
  return handedTo;
}

static NSPoint
center(NSRect r)
{
  return NSMakePoint(NSMidX(r), NSMidY(r));
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenuView submenu precedence")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name]
            isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NSMenu *deepest = menuWithSubmenu(@"Deepest", nil);
  NSMenu *middle = menuWithSubmenu(@"Middle", deepest);
  NSMenu *root = menuWithSubmenu(@"Root", middle);
  NSMenuView *rootView = (NSMenuView *)[root menuRepresentation];
  NSMenuView *middleView = (NSMenuView *)[middle menuRepresentation];
  NSMenuView *deepestView = (NSMenuView *)[deepest menuRepresentation];
  Method m = class_getInstanceMethod([NSMenuView class],
                                     @selector(_trackWithEvent:startingMenuView:));

  originalTrack = method_setImplementation(m, (IMP)recordingTrack);

  [root display];
  [rootView attachSubmenuForItemAtIndex: 0];
  [middleView attachSubmenuForItemAtIndex: 0];

  NSWindow *rootWindow = [root window];
  NSWindow *middleWindow = [middle window];
  NSWindow *deepestWindow = [deepest window];
  NSRect rootFrame;
  NSRect middleFrame;
  NSRect deepestFrame;

  [rootWindow setFrameOrigin: NSMakePoint(100, 300)];
  rootFrame = [rootWindow frame];
  [middleWindow setFrameOrigin:
    NSMakePoint(NSMaxX(rootFrame), NSMinY(rootFrame))];
  middleFrame = [middleWindow frame];

  /* 1. The deepest menu opened on the left of the middle one, covering the
   *    root menu. */
  [deepestWindow setFrameOrigin:
    NSMakePoint(NSMinX(middleFrame) - NSWidth([deepestWindow frame]),
                NSMinY(rootFrame))];
  deepestFrame = [deepestWindow frame];
  PASS(NSIntersectsRect(deepestFrame, rootFrame)
       && !NSMouseInRect(center(deepestFrame), middleFrame, NO),
       "the deepest menu covers the root menu, not the middle one");
  PASS(trackFrom(middleView, center(deepestFrame)) == deepestView,
       "the pointer over a submenu that covers an ancestor menu goes to "
       "the submenu");

  /* 2. The deepest menu covering the menu it is attached to (no room on
   *    either side). */
  [middleView attachSubmenuForItemAtIndex: 0];
  [deepestWindow setFrameOrigin:
    NSMakePoint(NSMinX(middleFrame) + NSWidth(middleFrame) / 4,
                NSMinY(middleFrame) - NSHeight(middleFrame) / 2)];
  deepestFrame = [deepestWindow frame];
  NSPoint overlap = center(NSIntersectionRect(deepestFrame, middleFrame));
  PASS(NSMouseInRect(overlap, middleFrame, NO)
       && NSMouseInRect(overlap, deepestFrame, NO),
       "the deepest menu covers the menu it is attached to");
  PASS(trackFrom(middleView, overlap) == deepestView,
       "the pointer over a submenu that covers its own parent menu goes to "
       "the submenu");

  /* 3. Nothing deeper under the pointer: an ancestor still gets it. */
  [middleView attachSubmenuForItemAtIndex: 0];
  [deepestWindow setFrameOrigin:
    NSMakePoint(NSMaxX(middleFrame), NSMinY(middleFrame))];
  PASS(trackFrom(middleView, center(rootFrame)) == rootView,
       "the pointer over an uncovered ancestor menu goes to the ancestor");

  method_setImplementation(m, originalTrack);

  END_SET("NSMenuView submenu precedence")

  DESTROY(arp);
  return 0;
}
