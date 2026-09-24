/* Lifetime exercise for NSMenu: -performActionForItemAtIndex: keeps using the
   menu after the action it sends has returned, because it posts
   NSMenuDidSendActionNotification naming the menu.  An action is allowed to
   throw away the widget that sent it - a form that regenerates its controls
   when a value changes drops the popup that was just used, and the popup owns
   its menu - so the last reference to the sender can go while the method is
   still running, leaving the rest of it on freed memory.  The sender is now
   held for the current autorelease scope, so the menu survives its own action,
   finishes the send, and is still valid to the caller afterwards.  The
   dispatch runs directly, so no window-server event loop is needed, but the
   set keeps the usual backend skip guard because building the menu items
   touches the graphics backend. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSObject.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>

static BOOL sending = NO;
static BOOL deallocated = NO;
static BOOL deallocatedWhileSending = NO;

/* A menu that reports its own death, since the test drops the only reference
   to it from inside the action it is sending. */
@interface WatchedMenu : NSMenu
@end

@implementation WatchedMenu
- (void) dealloc
{
  deallocated = YES;
  if (sending == YES)
    {
      deallocatedWhileSending = YES;
    }
  [super dealloc];
}
@end

@interface Releaser : NSObject
{
@public
  NSMenu *menu;
  int count;
  BOOL didPosted;
}
- (void) fired: (id)sender;
- (void) didSend: (NSNotification *)n;
@end

@implementation Releaser
- (void) fired: (id)sender
{
  count++;
  /* The action throws away the widget that sent it: the menu owns the item
     the action came from, and this is the only reference left to either. */
  DESTROY(menu);
}
- (void) didSend: (NSNotification *)n
{
  didPosted = YES;
}
@end

int
main(int argc, const char **argv)
{
  NSAutoreleasePool *setup;
  Releaser *r;
  WatchedMenu *menu;
  NSMenuItem *item;
  NSNotificationCenter *nc;

  START_SET("NSMenu actionSenderLifetime")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      r = AUTORELEASE([[Releaser alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      /* Build the menu in a pool of its own and drain it: adding an item
         posts an autoreleased notification that holds the menu, and the
         reference handed to the target has to be the last one for the action
         below to drop the menu the way a rebuilt form drops its popup. */
      setup = [NSAutoreleasePool new];
      menu = [[WatchedMenu alloc] initWithTitle: @"m"];
      [menu setAutoenablesItems: NO];
      item = [menu addItemWithTitle: @"Go"
                             action: @selector(fired:)
                      keyEquivalent: @""];
      [item setTarget: r];
      [item setEnabled: YES];
      r->menu = menu;
      [setup release];

      [nc addObserver: r
             selector: @selector(didSend:)
                 name: NSMenuDidSendActionNotification
               object: menu];

      sending = YES;
      [menu performActionForItemAtIndex: 0];
      sending = NO;

      /* Control: the action has to run at all for the rest to mean
         anything. */
      PASS(r->count == 1, "performActionForItemAtIndex: sends the item action");

      PASS(deallocatedWhileSending == NO,
        "the menu outlives the action that released it");
      PASS(deallocated == NO,
        "the menu is still alive when performActionForItemAtIndex: returns");

      /* Read through the reference the action dropped: sane only because the
         sender was held for the duration of the send. */
      PASS([[menu title] isEqualToString: @"m"],
        "the released menu is still readable after the action");
      PASS([menu numberOfItems] == 1,
        "the released menu still reports its item after the action");

      /* Control: the did action notification names the menu, so it is this
         posting that ran on a freed sender before the fix. */
      PASS(r->didPosted == YES,
        "the did action notification is posted after the action");

      [nc removeObserver: r];
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMenu actionSenderLifetime")

  return 0;
}
