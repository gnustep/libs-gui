/* Interaction exercise for NSMenu: -performActionForItemAtIndex: sends the
   item's action to its target and posts the will/did action notifications, a
   disabled item does nothing, and the notification user info carries the item.
   The dispatch runs directly, so no window-server event loop is needed, but
   the set keeps the usual backend skip guard because building the menu items
   touches the graphics backend. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>

@interface Recorder : NSObject
{
@public
  int count;
  id sender;
  BOOL willPosted;
  BOOL didPosted;
  id willItem;
}
- (void) fired: (id)s;
- (void) willSend: (NSNotification *)n;
- (void) didSend: (NSNotification *)n;
@end

@implementation Recorder
- (void) fired: (id)s
{
  count++;
  sender = s;
}
- (void) willSend: (NSNotification *)n
{
  willPosted = YES;
  willItem = [[n userInfo] objectForKey: @"MenuItem"];
}
- (void) didSend: (NSNotification *)n
{
  didPosted = YES;
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  Recorder *r;
  NSMenu *menu;
  NSMenuItem *item;
  NSNotificationCenter *nc;

  START_SET("NSMenu performAction")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      r = AUTORELEASE([[Recorder alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      menu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"m"]);
      [menu setAutoenablesItems: NO];
      item = [menu addItemWithTitle: @"Go"
                             action: @selector(fired:)
                      keyEquivalent: @""];
      [item setTarget: r];
      [item setEnabled: YES];

      [nc addObserver: r
             selector: @selector(willSend:)
                 name: NSMenuWillSendActionNotification
               object: menu];
      [nc addObserver: r
             selector: @selector(didSend:)
                 name: NSMenuDidSendActionNotification
               object: menu];

      /* An enabled item sends its action and posts both notifications. */
      [menu performActionForItemAtIndex: 0];
      PASS(r->count == 1, "performActionForItemAtIndex: sends the item action");
      PASS(r->sender == item, "the action's sender is the menu item");
      PASS(r->willPosted == YES && r->didPosted == YES,
        "the will and did action notifications are posted");
      PASS(r->willItem == item,
        "the notification user info carries the menu item");

      /* A disabled item does nothing and posts no notifications. */
      r->count = 0;
      r->willPosted = NO;
      r->didPosted = NO;
      [item setEnabled: NO];
      [menu performActionForItemAtIndex: 0];
      PASS(r->count == 0, "a disabled item sends no action");
      PASS(r->willPosted == NO && r->didPosted == NO,
        "a disabled item posts no notifications");

      [nc removeObserver: r];
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMenu performAction")

  DESTROY(arp);
  return 0;
}
