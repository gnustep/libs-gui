/* Attaching a menu to a menu item must not change the menu's own title, as
   reported in gnustep/libs-gui#218 ("NSMenu ignores initWithTitle").  A menu's
   title and the title of the item it is attached to are independent.  Every
   assertion was checked against Apple AppKit (macOS 26) and matches.  Creating
   a menu pulls in its windows, which needs the backend, so the body is
   guarded. */
#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSMenu submenu title")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  /* initWithTitle: keeps the title. */
  NSMenu *menu = AUTORELEASE([[NSMenu alloc] initWithTitle: @"File"]);
  PASS([[menu title] isEqualToString: @"File"],
       "-initWithTitle: keeps the title");

  /* The reporter's case: attaching the menu to a fresh item must not wipe the
     menu's title. */
  NSMenuItem *item = AUTORELEASE([NSMenuItem new]);
  [item setSubmenu: menu];
  PASS([[menu title] isEqualToString: @"File"],
       "-setSubmenu: does not change the submenu's title");

  /* A titled item does not rename its submenu either, and the item keeps its
     own title. */
  NSMenu *other = AUTORELEASE([[NSMenu alloc] initWithTitle: @"Colours"]);
  NSMenuItem *format = AUTORELEASE([[NSMenuItem alloc] initWithTitle: @"Format"
                                                              action: NULL
                                                       keyEquivalent: @""]);
  [format setSubmenu: other];
  PASS([[other title] isEqualToString: @"Colours"],
       "-setSubmenu: leaves a titled submenu's title alone");
  PASS([[format title] isEqualToString: @"Format"],
       "-setSubmenu: leaves the item's own title alone");

  /* The NSMenu convenience -setSubmenu:forItem: behaves the same way. */
  NSMenu *main = AUTORELEASE([[NSMenu alloc] initWithTitle: @"Main"]);
  NSMenuItem *entry = [main addItemWithTitle: @"Edit"
                                      action: NULL
                               keyEquivalent: @""];
  NSMenu *edit = AUTORELEASE([[NSMenu alloc] initWithTitle: @"Edit menu"]);
  [main setSubmenu: edit forItem: entry];
  PASS([[edit title] isEqualToString: @"Edit menu"],
       "-setSubmenu:forItem: does not change the submenu's title");

  END_SET("NSMenu submenu title")

  DESTROY(arp);
  return 0;
}
