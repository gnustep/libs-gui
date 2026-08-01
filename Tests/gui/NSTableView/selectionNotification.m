/* NSTableView posts NSTableViewSelectionDidChangeNotification when a
   programmatic row selection changes, does not repost when the same rows are
   selected again, and posts when the selection is cleared.  selection.m covers
   the selected-index state; this covers the change notification.  The table
   view uses the theme and font backend, so the set is skipped when the backend
   is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSIndexSet.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>

@interface Source : NSObject
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv;
- (id) tableView: (NSTableView *)tv
  objectValueForTableColumn: (NSTableColumn *)col
             row: (NSInteger)row;
@end

@implementation Source
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv
{
  return 5;
}
- (id) tableView: (NSTableView *)tv
  objectValueForTableColumn: (NSTableColumn *)col
             row: (NSInteger)row
{
  return @"x";
}
@end

@interface Recorder : NSObject
{
@public
  int count;
}
- (void) changed: (NSNotification *)n;
@end

@implementation Recorder
- (void) changed: (NSNotification *)n
{
  count++;
}
@end

int
main(int argc, char **argv)
{
  Source *ds;
  Recorder *r;
  NSTableView *tv;
  NSTableColumn *col;
  NSNotificationCenter *nc;

  START_SET("NSTableView selection notification")

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
      ds = AUTORELEASE([[Source alloc] init]);
      r = AUTORELEASE([[Recorder alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);
      col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"c"]);
      [tv addTableColumn: col];
      [tv setDataSource: ds];
      [tv reloadData];

      [nc addObserver: r
             selector: @selector(changed:)
                 name: NSTableViewSelectionDidChangeNotification
               object: tv];

      /* Selecting a new row posts the change notification. */
      [tv selectRowIndexes: [NSIndexSet indexSetWithIndex: 2]
        byExtendingSelection: NO];
      PASS(r->count == 1 && [tv selectedRow] == 2,
        "selecting a new row posts the change notification");

      /* Selecting the same row again posts nothing. */
      [tv selectRowIndexes: [NSIndexSet indexSetWithIndex: 2]
        byExtendingSelection: NO];
      PASS(r->count == 1,
        "selecting the same row again does not repost");

      /* Selecting a different row posts again. */
      [tv selectRowIndexes: [NSIndexSet indexSetWithIndex: 4]
        byExtendingSelection: NO];
      PASS(r->count == 2 && [tv selectedRow] == 4,
        "selecting a different row posts again");

      /* Clearing the selection posts the change notification. */
      [tv deselectAll: nil];
      PASS(r->count == 3 && [tv selectedRow] == -1,
        "clearing the selection posts the change notification");

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

  END_SET("NSTableView selection notification")

  return 0;
}
