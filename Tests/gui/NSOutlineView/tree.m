/* Coverage for NSOutlineView's item tree: expand and collapse, the row/item
   mapping, levels and parent, driven by a small tree data source. Every
   assertion matches AppKit (checked on a macOS runner) and passes on
   unmodified GNUstep.

   Tree: root has A and B; A has A1 and A2; B and the leaves have no children. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSOutlineView.h>
#include <AppKit/NSTableColumn.h>

@interface Tree : NSObject
@end
@implementation Tree
- (NSArray *) childrenOf: (id)item
{
  if (item == nil) return [NSArray arrayWithObjects: @"A", @"B", nil];
  if ([item isEqual: @"A"]) return [NSArray arrayWithObjects: @"A1", @"A2", nil];
  return [NSArray array];
}
- (NSInteger) outlineView: (NSOutlineView *)ov numberOfChildrenOfItem: (id)item
{ return [[self childrenOf: item] count]; }
- (id) outlineView: (NSOutlineView *)ov child: (NSInteger)i ofItem: (id)item
{ return [[self childrenOf: item] objectAtIndex: i]; }
- (BOOL) outlineView: (NSOutlineView *)ov isItemExpandable: (id)item
{ return [[self childrenOf: item] count] > 0; }
- (id) outlineView: (NSOutlineView *)ov
       objectValueForTableColumn: (NSTableColumn *)col
       byItem: (id)item
{ return item; }
@end

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSOutlineView *ov;
  NSTableColumn *col;
  Tree *ds;

  START_SET("NSOutlineView tree")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      ov = AUTORELEASE([[NSOutlineView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);
      col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"c"]);
      [col setWidth: 100.0];
      [ov addTableColumn: col];
      [ov setOutlineTableColumn: col];
      pass([ov outlineTableColumn] == col, "outlineTableColumn round-trips");
      ds = AUTORELEASE([Tree new]);
      [ov setDataSource: ds];
      [ov reloadData];

      pass([ov numberOfRows] == 2, "a collapsed tree shows its two roots");
      pass([ov isExpandable: @"A"] == YES, "A is expandable");
      pass([ov isExpandable: @"B"] == NO, "B is not expandable");
      pass([ov isItemExpanded: @"A"] == NO, "A is collapsed to start");
      pass([[ov itemAtRow: 0] isEqual: @"A"], "row 0 is A");
      pass([ov rowForItem: @"B"] == 1, "B is at row 1 while collapsed");
      pass([ov levelForRow: 0] == 0, "a root is at level 0");

      [ov expandItem: @"A"];
      pass([ov numberOfRows] == 4, "expanding A reveals its two children");
      pass([ov isItemExpanded: @"A"] == YES, "A is expanded");
      pass([[ov itemAtRow: 1] isEqual: @"A1"], "row 1 is A1 after expanding");
      pass([ov levelForItem: @"A1"] == 1, "A1 is at level 1");
      pass([ov levelForRow: 1] == 1, "row 1 is at level 1");
      pass([[ov parentForItem: @"A1"] isEqual: @"A"], "A1's parent is A");
      pass([ov rowForItem: @"B"] == 3, "B moves to row 3 after expanding A");

      [ov collapseItem: @"A"];
      pass([ov numberOfRows] == 2, "collapsing A hides its children");
      pass([ov isItemExpanded: @"A"] == NO, "A is collapsed again");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOutlineView tree")

  DESTROY(arp);
  return 0;
}
