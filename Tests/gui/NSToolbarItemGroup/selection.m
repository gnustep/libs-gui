/* The selection a group keeps for its subitems: which indexes are selected,
 * which was selected last, and how each selection mode treats a change.
 */
#include "Testing.h"

#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbarItem.h>
#include <AppKit/NSToolbarItemGroup.h>

static NSToolbarItemGroup *
groupWithMode(NSToolbarItemGroupSelectionMode mode)
{
  NSToolbarItemGroup	*group;
  NSMutableArray	*subitems;
  NSUInteger		i;

  group = AUTORELEASE([[NSToolbarItemGroup alloc]
    initWithItemIdentifier: @"group"]);
  subitems = [NSMutableArray array];
  for (i = 0; i < 3; i++)
    {
      NSString		*identifier;
      NSToolbarItem	*subitem;

      identifier = [NSString stringWithFormat: @"i%lu", (unsigned long)i];
      subitem = AUTORELEASE([[NSToolbarItem alloc]
        initWithItemIdentifier: identifier]);
      [subitems addObject: subitem];
    }
  [group setSubitems: subitems];
  [group setSelectionMode: mode];
  return group;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("selection")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  {
    NSToolbarItemGroup	*group;
    BOOL		raised;

    /* the enumerations */
    PASS(NSToolbarItemGroupSelectionModeSelectOne == 0
      && NSToolbarItemGroupSelectionModeSelectAny == 1
      && NSToolbarItemGroupSelectionModeMomentary == 2,
      "the selection modes have their AppKit values");
    PASS(NSToolbarItemGroupControlRepresentationAutomatic == 0
      && NSToolbarItemGroupControlRepresentationExpanded == 1
      && NSToolbarItemGroupControlRepresentationCollapsed == 2,
      "the control representations have their AppKit values");

    /* defaults */
    group = AUTORELEASE([[NSToolbarItemGroup alloc]
      initWithItemIdentifier: @"group"]);
    PASS([group selectionMode] == NSToolbarItemGroupSelectionModeSelectOne,
      "a new group selects one subitem");
    PASS([group controlRepresentation]
      == NSToolbarItemGroupControlRepresentationAutomatic,
      "a new group has the automatic control representation");
    PASS([group selectedIndex] == -1, "a new group has nothing selected");

    /* round-trips */
    [group setSelectionMode: NSToolbarItemGroupSelectionModeSelectAny];
    PASS([group selectionMode] == NSToolbarItemGroupSelectionModeSelectAny,
      "the selection mode round-trips");
    [group setControlRepresentation:
      NSToolbarItemGroupControlRepresentationCollapsed];
    PASS([group controlRepresentation]
      == NSToolbarItemGroupControlRepresentationCollapsed,
      "the control representation round-trips");

    /* selecting one */
    group = groupWithMode(NSToolbarItemGroupSelectionModeSelectOne);
    PASS([group selectedIndex] == -1,
      "a group with subitems starts with nothing selected");
    PASS([group isSelectedAtIndex: 0] == NO,
      "no subitem starts out selected");

    [group setSelected: YES atIndex: 0];
    PASS([group selectedIndex] == 0 && [group isSelectedAtIndex: 0] == YES,
      "selecting a subitem selects it");

    [group setSelected: YES atIndex: 2];
    PASS([group selectedIndex] == 2 && [group isSelectedAtIndex: 2] == YES
      && [group isSelectedAtIndex: 0] == NO,
      "selecting another subitem deselects the first when selecting one");

    [group setSelected: NO atIndex: 2];
    PASS([group isSelectedAtIndex: 2] == YES && [group selectedIndex] == 2,
      "a group that selects one keeps its subitem selected");

    /* selecting any */
    group = groupWithMode(NSToolbarItemGroupSelectionModeSelectAny);
    [group setSelected: YES atIndex: 2];
    [group setSelected: YES atIndex: 0];
    PASS([group isSelectedAtIndex: 0] == YES
      && [group isSelectedAtIndex: 2] == YES,
      "a group that selects any keeps both subitems selected");
    PASS([group selectedIndex] == 0,
      "the selected index is the subitem selected last");

    [group setSelected: NO atIndex: 2];
    PASS([group isSelectedAtIndex: 2] == NO
      && [group isSelectedAtIndex: 0] == YES,
      "a group that selects any deselects a subitem");
    PASS([group selectedIndex] == 0,
      "deselecting a subitem leaves the selected index alone");

    /* momentary */
    group = groupWithMode(NSToolbarItemGroupSelectionModeMomentary);
    [group setSelected: YES atIndex: 1];
    PASS([group isSelectedAtIndex: 1] == NO && [group selectedIndex] == -1,
      "a momentary group does not hold a selection");
    [group setSelectedIndex: 1];
    PASS([group selectedIndex] == 1 && [group isSelectedAtIndex: 1] == NO,
      "a momentary group records the selected index without selecting");

    /* setSelectedIndex: */
    group = groupWithMode(NSToolbarItemGroupSelectionModeSelectOne);
    [group setSelectedIndex: 1];
    PASS([group selectedIndex] == 1 && [group isSelectedAtIndex: 1] == YES,
      "setting the selected index selects that subitem");

    group = groupWithMode(NSToolbarItemGroupSelectionModeSelectAny);
    [group setSelected: YES atIndex: 0];
    [group setSelectedIndex: 1];
    PASS([group isSelectedAtIndex: 0] == YES
      && [group isSelectedAtIndex: 1] == YES && [group selectedIndex] == 1,
      "setting the selected index adds to the selection when selecting any");

    group = groupWithMode(NSToolbarItemGroupSelectionModeSelectOne);
    [group setSelected: YES atIndex: 1];
    [group setSelectedIndex: -1];
    PASS([group selectedIndex] == 1 && [group isSelectedAtIndex: 1] == YES,
      "setting the selected index to -1 leaves the selection alone");

    /* the mode leaves an existing selection alone */
    group = groupWithMode(NSToolbarItemGroupSelectionModeSelectAny);
    [group setSelected: YES atIndex: 0];
    [group setSelected: YES atIndex: 2];
    [group setSelectionMode: NSToolbarItemGroupSelectionModeSelectOne];
    PASS([group isSelectedAtIndex: 0] == YES
      && [group isSelectedAtIndex: 2] == YES && [group selectedIndex] == 2,
      "changing the selection mode leaves the selection alone");

    /* replacing the subitems */
    group = groupWithMode(NSToolbarItemGroupSelectionModeSelectOne);
    [group setSelected: YES atIndex: 2];
    [group setSubitems: [NSArray arrayWithObject:
      AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"x"])]];
    PASS([group selectedIndex] == -1 && [group isSelectedAtIndex: 0] == NO,
      "replacing the subitems clears the selection");

    /* out of range */
    group = groupWithMode(NSToolbarItemGroupSelectionModeSelectOne);
    raised = NO;
    NS_DURING
      [group isSelectedAtIndex: 99];
    NS_HANDLER
      raised = [[localException name] isEqualToString: NSRangeException];
    NS_ENDHANDLER
    PASS(raised == YES, "asking about an index out of range raises");

    raised = NO;
    NS_DURING
      [group setSelected: YES atIndex: 99];
    NS_HANDLER
      raised = [[localException name] isEqualToString: NSRangeException];
    NS_ENDHANDLER
    PASS(raised == YES, "selecting an index out of range raises");

    raised = NO;
    NS_DURING
      [group setSelectedIndex: 99];
    NS_HANDLER
      raised = [[localException name] isEqualToString: NSRangeException];
    NS_ENDHANDLER
    PASS(raised == YES, "setting the selected index out of range raises");
  }

  END_SET("selection")

  DESTROY(arp);
  return 0;
}
