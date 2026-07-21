/* Coverage for NSTableView column management: add, the identifier lookup and
   back-pointer, tableColumns membership, move and remove. Every assertion
   matches AppKit (checked on a macOS runner) and passes on unmodified
   GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTableColumn.h>

static NSTableColumn *
mkcol(NSString *ident)
{
  NSTableColumn *c = AUTORELEASE([[NSTableColumn alloc]
    initWithIdentifier: ident]);
  [c setWidth: 50.0];
  return c;
}

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableView *tv;
  NSTableColumn *c1, *c2;

  START_SET("NSTableView columns")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      c1 = mkcol(@"c1");
      c2 = mkcol(@"c2");

      [tv addTableColumn: c1];
      [tv addTableColumn: c2];
      pass([tv numberOfColumns] == 2, "two columns were added");
      pass([c1 tableView] == tv, "an added column points back at the table");
      pass([tv columnWithIdentifier: @"c2"] == 1,
           "columnWithIdentifier: finds c2 at index 1");
      pass([[tv tableColumns] containsObject: c1],
           "tableColumns contains an added column");
      pass([[tv tableColumns] objectAtIndex: 0] == c1,
           "the first column is the first one added");

      [tv moveColumn: 0 toColumn: 1];
      pass([[tv tableColumns] objectAtIndex: 0] == c2,
           "moveColumn:toColumn: reorders the columns");

      [tv removeTableColumn: c1];
      pass([tv numberOfColumns] == 1, "removeTableColumn: lowers the count");
      pass([[tv tableColumns] objectAtIndex: 0] == c2,
           "the remaining column is the one not removed");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTableView columns")

  DESTROY(arp);
  return 0;
}
