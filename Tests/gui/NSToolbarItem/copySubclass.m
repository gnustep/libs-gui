/* -copyWithZone: copies into the receiver's own class, so that copying a
 * subclass such as NSToolbarItemGroup or NSMenuToolbarItem returns an instance
 * of that subclass.  A group whose copy is a plain NSToolbarItem cannot carry
 * the subitems over, since a plain item does not respond to -setSubitems:.
 */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMenuToolbarItem.h>
#include <AppKit/NSToolbarItem.h>
#include <AppKit/NSToolbarItemGroup.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("copying a toolbar item subclass")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSToolbarItem	*item;
    NSToolbarItem	*plainCopy;
    NSToolbarItemGroup	*group;
    NSToolbarItem	*subitem;
    NSToolbarItemGroup	*groupCopy = nil;
    NSMenuToolbarItem	*menuItem;
    NSMenuToolbarItem	*menuCopy = nil;

    /* A plain item still copies as before. */
    item = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"a"]);
    [item setLabel: @"L"];
    plainCopy = AUTORELEASE([item copy]);
    PASS([plainCopy isMemberOfClass: [NSToolbarItem class]],
      "copying a toolbar item returns a toolbar item");
    PASS([[plainCopy itemIdentifier] isEqualToString: @"a"],
      "the copy keeps the item identifier");
    PASS([[plainCopy label] isEqualToString: @"L"],
      "the copy keeps the label");

    group = AUTORELEASE([[NSToolbarItemGroup alloc]
      initWithItemIdentifier: @"group"]);
    subitem = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"s"]);
    [group setSubitems: [NSArray arrayWithObject: subitem]];

    NS_DURING
      groupCopy = AUTORELEASE([group copy]);
    NS_HANDLER
      groupCopy = nil;
    NS_ENDHANDLER

    PASS(groupCopy != nil, "copying a toolbar item group does not raise");
    PASS([groupCopy isMemberOfClass: [NSToolbarItemGroup class]],
      "copying a toolbar item group returns a toolbar item group");
    PASS([[groupCopy itemIdentifier] isEqualToString: @"group"],
      "the group copy keeps the item identifier");
    PASS([[groupCopy subitems] count] == 1,
      "the group copy keeps the subitems");

    menuItem = AUTORELEASE([[NSMenuToolbarItem alloc]
      initWithItemIdentifier: @"menu"]);

    NS_DURING
      menuCopy = AUTORELEASE([menuItem copy]);
    NS_HANDLER
      menuCopy = nil;
    NS_ENDHANDLER

    PASS([menuCopy isMemberOfClass: [NSMenuToolbarItem class]],
      "copying a menu toolbar item returns a menu toolbar item");
  }

  END_SET("copying a toolbar item subclass")

  DESTROY(arp);
  return 0;
}
