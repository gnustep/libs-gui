/* NSOutlineView posts NSOutlineViewItemDidExpandNotification when an expandable
   item is expanded and NSOutlineViewItemDidCollapseNotification when it is
   collapsed, tracks the expanded state, and does not repost when the item is
   already in the requested state.  The notification user info carries the item.
   The outline view uses the theme and font backend, so the set is skipped when
   the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSOutlineView.h>

/* A two-level tree: the root holds one expandable "parent", which holds one
   leaf "child". */
@interface Tree : NSObject
@end

@implementation Tree
- (NSInteger) outlineView: (NSOutlineView *)ov numberOfChildrenOfItem: (id)item
{
  if (item == nil)
    return 1;
  if ([item isEqual: @"parent"])
    return 1;
  return 0;
}
- (id) outlineView: (NSOutlineView *)ov child: (NSInteger)index ofItem: (id)item
{
  if (item == nil)
    return @"parent";
  return @"child";
}
- (BOOL) outlineView: (NSOutlineView *)ov isItemExpandable: (id)item
{
  return [item isEqual: @"parent"];
}
- (id) outlineView: (NSOutlineView *)ov
  objectValueForTableColumn: (NSTableColumn *)col
            byItem: (id)item
{
  return item;
}
@end

@interface Recorder : NSObject
{
@public
  int expandCount;
  int collapseCount;
  id lastItem;
}
- (void) didExpand: (NSNotification *)n;
- (void) didCollapse: (NSNotification *)n;
@end

@implementation Recorder
- (void) didExpand: (NSNotification *)n
{
  expandCount++;
  lastItem = [[n userInfo] objectForKey: @"NSObject"];
}
- (void) didCollapse: (NSNotification *)n
{
  collapseCount++;
}
@end

int
main(int argc, char **argv)
{
  Tree *ds;
  Recorder *r;
  NSOutlineView *ov;
  NSTableColumn *col;
  NSNotificationCenter *nc;

  START_SET("NSOutlineView expand notification")

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
      ds = AUTORELEASE([[Tree alloc] init]);
      r = AUTORELEASE([[Recorder alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      ov = AUTORELEASE([[NSOutlineView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);
      col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"c"]);
      [ov addTableColumn: col];
      [ov setOutlineTableColumn: col];
      [ov setDataSource: ds];
      [ov reloadData];

      [nc addObserver: r
             selector: @selector(didExpand:)
                 name: NSOutlineViewItemDidExpandNotification
               object: ov];
      [nc addObserver: r
             selector: @selector(didCollapse:)
                 name: NSOutlineViewItemDidCollapseNotification
               object: ov];

      /* Expanding an expandable item posts the did-expand notification. */
      [ov expandItem: @"parent"];
      PASS(r->expandCount == 1 && [ov isItemExpanded: @"parent"] == YES,
        "expanding an item posts the did-expand notification");
      PASS([r->lastItem isEqual: @"parent"],
        "the notification user info carries the expanded item");

      /* Expanding it again posts nothing. */
      [ov expandItem: @"parent"];
      PASS(r->expandCount == 1, "expanding an already expanded item does nothing");

      /* Collapsing it posts the did-collapse notification. */
      [ov collapseItem: @"parent"];
      PASS(r->collapseCount == 1 && [ov isItemExpanded: @"parent"] == NO,
        "collapsing an item posts the did-collapse notification");

      /* Collapsing it again posts nothing. */
      [ov collapseItem: @"parent"];
      PASS(r->collapseCount == 1,
        "collapsing an already collapsed item does nothing");

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

  END_SET("NSOutlineView expand notification")

  return 0;
}
