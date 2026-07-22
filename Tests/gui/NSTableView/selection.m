/* Coverage for NSTableView row selection driven by a data source: multiple
   selection, isRowSelected:, selectedRow, deselectRow: and deselectAll:. Every
   assertion matches AppKit (checked on a macOS runner) and passes on
   unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSIndexSet.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTableColumn.h>

@interface TVDS : NSObject
@end
@implementation TVDS
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv { return 5; }
- (id) tableView: (NSTableView *)tv
       objectValueForTableColumn: (NSTableColumn *)col
       row: (NSInteger)row
{ return [NSString stringWithFormat: @"r%ld", (long)row]; }
@end

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableView *tv;
  TVDS *ds;
  NSTableColumn *col;

  START_SET("NSTableView selection")

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
      col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"a"]);
      [col setWidth: 50.0];
      [tv addTableColumn: col];
      ds = AUTORELEASE([TVDS new]);
      [tv setDataSource: ds];
      [tv reloadData];
      PASS([tv numberOfRows] == 5, "the data source drives numberOfRows");

      [tv setAllowsMultipleSelection: YES];
      [tv selectRowIndexes: [NSIndexSet indexSetWithIndex: 1]
        byExtendingSelection: NO];
      [tv selectRowIndexes: [NSIndexSet indexSetWithIndex: 3]
        byExtendingSelection: YES];
      PASS([tv numberOfSelectedRows] == 2, "two rows are selected");
      PASS([tv isRowSelected: 1] == YES, "row 1 is selected");
      PASS([tv isRowSelected: 0] == NO, "row 0 is not selected");
      PASS([tv selectedRow] == 3, "selectedRow is the last selected row");

      [tv deselectRow: 1];
      PASS([tv isRowSelected: 1] == NO, "deselectRow: clears that row");
      PASS([tv numberOfSelectedRows] == 1, "one row remains selected");

      [tv deselectAll: nil];
      PASS([tv numberOfSelectedRows] == 0, "deselectAll: clears the selection");
      PASS([tv selectedRow] == -1, "selectedRow is -1 after deselectAll:");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTableView selection")

  DESTROY(arp);
  return 0;
}
