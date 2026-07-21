/* A new cell view sizes its row itself until a table view gives it one of the
 * standard row size styles.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableCellView.h>
#include <AppKit/NSTableView.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("the default row size style")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSTableCellView	*view;

    view = AUTORELEASE([[NSTableCellView alloc]
      initWithFrame: NSMakeRect(0, 0, 100, 20)]);
    PASS([view rowSizeStyle] == NSTableViewRowSizeStyleCustom,
      "a new cell view has the custom row size style");

    view = AUTORELEASE([[NSTableCellView alloc] init]);
    PASS([view rowSizeStyle] == NSTableViewRowSizeStyleCustom,
      "a cell view made with init has the custom row size style");

    [view setRowSizeStyle: NSTableViewRowSizeStyleLarge];
    PASS([view rowSizeStyle] == NSTableViewRowSizeStyleLarge,
      "the row size style round-trips");
  }

  END_SET("the default row size style")

  DESTROY(arp);
  return 0;
}
