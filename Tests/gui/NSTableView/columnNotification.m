/* NSTableView posts NSTableViewColumnDidMoveNotification when a column is moved
   and NSTableViewColumnDidResizeNotification when a column width changes, with
   the old and new positions and the old width in the user info, and posts
   nothing for a no-op move or an unchanged width.  columns.m covers the column
   set; this covers the column notifications.  The table view uses the theme and
   font backend, so the set is skipped when the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>

@interface Recorder : NSObject
{
@public
  int moveCount;
  NSInteger oldCol;
  NSInteger newCol;
  int resizeCount;
  CGFloat oldWidth;
  id resizeColumn;
}
- (void) didMove: (NSNotification *)n;
- (void) didResize: (NSNotification *)n;
@end

@implementation Recorder
- (void) didMove: (NSNotification *)n
{
  moveCount++;
  oldCol = [[[n userInfo] objectForKey: @"NSOldColumn"] integerValue];
  newCol = [[[n userInfo] objectForKey: @"NSNewColumn"] integerValue];
}
- (void) didResize: (NSNotification *)n
{
  resizeCount++;
  oldWidth = [[[n userInfo] objectForKey: @"NSOldWidth"] doubleValue];
  resizeColumn = [[n userInfo] objectForKey: @"NSTableColumn"];
}
@end

static NSTableColumn *
column(NSString *ident)
{
  return AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: ident]);
}

int
main(int argc, char **argv)
{
  Recorder *r;
  NSTableView *tv;
  NSTableColumn *c0;
  NSNotificationCenter *nc;

  START_SET("NSTableView column notification")

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
      r = AUTORELEASE([[Recorder alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 300, 100)]);
      c0 = column(@"c0");
      [tv addTableColumn: c0];
      [tv addTableColumn: column(@"c1")];
      [tv addTableColumn: column(@"c2")];

      [nc addObserver: r
             selector: @selector(didMove:)
                 name: NSTableViewColumnDidMoveNotification
               object: tv];
      [nc addObserver: r
             selector: @selector(didResize:)
                 name: NSTableViewColumnDidResizeNotification
               object: tv];

      /* Moving a column posts the move notification with old and new index. */
      [tv moveColumn: 0 toColumn: 2];
      PASS(r->moveCount == 1 && r->oldCol == 0 && r->newCol == 2,
        "moveColumn:toColumn: posts the move notification with the positions");

      /* Moving a column onto itself posts nothing. */
      [tv moveColumn: 1 toColumn: 1];
      PASS(r->moveCount == 1, "a no-op move posts nothing");

      /* Changing a column width posts the resize notification with old width. */
      [c0 setWidth: 150.0];
      PASS(r->resizeCount == 1 && r->oldWidth == 100.0 && r->resizeColumn == c0,
        "setWidth: posts the resize notification with the old width and column");

      /* Setting the same width posts nothing. */
      [c0 setWidth: 150.0];
      PASS(r->resizeCount == 1, "setting the same width posts nothing");

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

  END_SET("NSTableView column notification")

  return 0;
}
