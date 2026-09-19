/* Releasing the mouse away from a menu must carry out no item.  An item
 * whose submenu has just been attached keeps the highlight while the
 * pointer is away from the menu, and that highlight used to be carried out
 * when the mouse was released somewhere else.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDate.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSString.h>
#include <Foundation/NSTimer.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSWindow.h>
#include <GNUstepGUI/GSDisplayServer.h>
#include <signal.h>
#include <unistd.h>

static NSString *performed = nil;
static NSPoint awayPoint;
static BOOL moveAway = NO;
static int step = 0;

@interface Recorder : NSObject
- (void) hit: (id)sender;
- (void) tick: (NSTimer *)timer;
@end

@implementation Recorder

- (void) hit: (id)sender
{
  ASSIGN(performed, [(NSMenuItem *)sender title]);
}

/* Tracking reads the pointer where it is now, so the move and the release
 * after it have to be separated by turns of the run loop. */
- (void) tick: (NSTimer *)timer
{
  step++;
  if (step == 1)
    {
      if (moveAway)
        {
          [GSCurrentServer() setMouseLocation: awayPoint onScreen: 0];
        }
    }
  else if (step == 2)
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

      [NSApp postEvent: up atStart: NO];
      [timer invalidate];
    }
}

@end

static void
timedOut(int sig)
{
  printf("Failed test:     clickOutside.m:0 ... menu tracking did not end\n");
  fflush(stdout);
  _exit(1);
}

/* Presses the mouse in the menu, moves the pointer away when asked to, and
 * releases it there.  Returns the title of the item that was carried out. */
static NSString *
clickAt(NSMenuView *view, NSPoint press, BOOL away)
{
  NSEvent *down;
  NSTimer *timer;

  DESTROY(performed);
  moveAway = away;
  step = 0;
  [GSCurrentServer() setMouseLocation: press onScreen: 0];
  down = [NSEvent mouseEventWithType: NSLeftMouseDown
                            location: NSZeroPoint
                       modifierFlags: 0
                           timestamp: 0
                        windowNumber: [[view window] windowNumber]
                             context: nil
                         eventNumber: 0
                          clickCount: 1
                            pressure: 0];
  timer = [NSTimer timerWithTimeInterval: 0.2
                                  target: AUTORELEASE([Recorder new])
                                selector: @selector(tick:)
                                userInfo: nil
                                 repeats: YES];
  [[NSRunLoop currentRunLoop] addTimer: timer
                               forMode: NSEventTrackingRunLoopMode];
  signal(SIGALRM, timedOut);
  alarm(20);
  [view mouseDown: down];
  alarm(0);
  [timer invalidate];
  return performed;
}

static NSPoint
center(NSRect r)
{
  return NSMakePoint(NSMidX(r), NSMidY(r));
}

/* The index of the item the pointer really is on, as the tracking loop
 * itself works it out. */
static int
itemUnderPointer(NSMenuView *view)
{
  NSPoint location = [[view window] mouseLocationOutsideOfEventStream];

  return [view indexOfItemAtPoint: [view convertPoint: location
                                            fromView: nil]];
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenuView click outside")

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

  Recorder *recorder = AUTORELEASE([Recorder new]);
  NSMenu *submenu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"Submenu"]);
  NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"Menu"]);
  NSMenuView *view;
  NSMenuItem *item;
  NSRect frame;
  NSPoint onItem;

  [submenu addItemWithTitle: @"Inside" action: NULL keyEquivalent: @""];
  [menu addItemWithTitle: @"Plain item" action: @selector(hit:)
          keyEquivalent: @""];
  item = (NSMenuItem *)[menu addItemWithTitle: @"Item with a submenu"
                                       action: @selector(hit:)
                                keyEquivalent: @""];
  [menu setSubmenu: submenu forItem: item];
  /* An item can have both a submenu and an action, as in a menu of folders
   * that open when they are clicked and list their contents when hovered. */
  [item setAction: @selector(hit:)];
  [[menu itemAtIndex: 0] setTarget: recorder];
  [item setTarget: recorder];
  [menu setAutoenablesItems: NO];

  view = (NSMenuView *)[menu menuRepresentation];
  /* Only in this style does releasing the mouse on an item whose submenu is
   * open carry the item out; in the other styles -_executeItemAtIndex:
   * stops there, so the highlight left behind could not be observed. */
  [view setInterfaceStyle: NSMacintoshInterfaceStyle];
  [menu display];
  [[menu window] setFrameOrigin: NSMakePoint(300, 400)];
  frame = [[menu window] frame];
  onItem = [[menu window] convertBaseToScreen:
    [view convertPoint: center([view rectOfItemAtIndex: 1]) toView: nil]];
  awayPoint = NSMakePoint(NSMinX(frame) - 40, NSMinY(frame) - 40);

  PASS(NSMouseInRect(onItem, frame, NO)
       && !NSMouseInRect(awayPoint, frame, NO),
       "the item is in the menu and the point clicked away from it is not");

  [GSCurrentServer() setMouseLocation: onItem onScreen: 0];
  if (itemUnderPointer(view) != 1)
    {
      SKIP("the display server does not place the pointer where it is told")
    }

  PASS_EQUAL(clickAt(view, onItem, NO), @"Item with a submenu",
             "releasing the mouse on an item carries it out");

  PASS(clickAt(view, onItem, YES) == nil,
       "releasing the mouse away from the menu carries out nothing");

  END_SET("NSMenuView click outside")

  DESTROY(arp);
  (void)argc;
  (void)argv;
  return 0;
}
