/* NSToolbar posts NSToolbarWillAddItemNotification when an item is inserted and
   NSToolbarDidRemoveItemNotification when one is removed, carrying the toolbar
   item in the user info, and keeps its item list in step.  The toolbar builds
   its items through the delegate and lays them out with the theme and font
   backend, so the set is skipped when the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbar.h>
#include <AppKit/NSToolbarItem.h>

/* A delegate that offers a single item identifier and builds a plain item for
   it; the default set is empty so building the toolbar inserts nothing. */
@interface TBDelegate : NSObject
@end

@implementation TBDelegate
- (NSToolbarItem *) toolbar: (NSToolbar *)tb
      itemForItemIdentifier: (NSString *)ident
  willBeInsertedIntoToolbar: (BOOL)flag
{
  return AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: ident]);
}
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObject: @"foo"];
}
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray array];
}
@end

@interface Recorder : NSObject
{
@public
  int addCount;
  int removeCount;
  id addedItem;
}
- (void) willAdd: (NSNotification *)n;
- (void) didRemove: (NSNotification *)n;
@end

@implementation Recorder
- (void) willAdd: (NSNotification *)n
{
  addCount++;
  addedItem = [[n userInfo] objectForKey: @"item"];
}
- (void) didRemove: (NSNotification *)n
{
  removeCount++;
}
@end

int
main(int argc, char **argv)
{
  TBDelegate *del;
  Recorder *r;
  NSToolbar *tb;
  NSNotificationCenter *nc;

  START_SET("NSToolbar item notification")

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

  NS_DURING
    {
      del = AUTORELEASE([[TBDelegate alloc] init]);
      r = AUTORELEASE([[Recorder alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      tb = AUTORELEASE([[NSToolbar alloc] initWithIdentifier: @"t"]);
      [tb setDelegate: del];

      [nc addObserver: r
             selector: @selector(willAdd:)
                 name: NSToolbarWillAddItemNotification
               object: tb];
      [nc addObserver: r
             selector: @selector(didRemove:)
                 name: NSToolbarDidRemoveItemNotification
               object: tb];

      /* Inserting an item posts the will-add notification with the item. */
      [tb insertItemWithItemIdentifier: @"foo" atIndex: 0];
      PASS(r->addCount == 1 && [[tb items] count] == 1,
        "inserting an item posts the will-add notification");
      PASS([[r->addedItem itemIdentifier] isEqualToString: @"foo"],
        "the notification user info carries the inserted item");

      /* Removing the item posts the did-remove notification. */
      [tb removeItemAtIndex: 0];
      PASS(r->removeCount == 1 && [[tb items] count] == 0,
        "removing an item posts the did-remove notification");

      [nc removeObserver: r];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSToolbar item notification")

  return 0;
}
