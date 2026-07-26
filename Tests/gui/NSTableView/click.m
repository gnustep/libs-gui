/* Interaction exercise for NSTableView: a real click on a row selects that
   row.  The click point is the centre of the row's rect, which is exact
   geometry, so this is not theme dependent.  selectionNotification.m drives the
   selection programmatically; this drives it with a genuine click.  The click
   is delivered as real events through GSClick, so this needs a window server
   and keeps the usual START_SET / SKIP guard. */
#import "Testing.h"
#import "../GSRenderTest.h"

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSWindow.h>

@interface Source : NSObject
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

static void
clickRow(NSWindow *w, NSTableView *tv, NSInteger row)
{
  NSRect r = [tv rectOfRow: row];
  GSClick(w, tv, NSMakePoint(NSMidX(r), NSMidY(r)));
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  Source *ds;
  NSTableView *tv;
  NSTableColumn *col;
  NSWindow *w;

  START_SET("NSTableView click")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      ds = AUTORELEASE([[Source alloc] init]);

      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 180, 100)]);
      col = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"c"]);
      [col setWidth: 160.0];
      [tv addTableColumn: col];
      [tv setDataSource: ds];
      [tv setRowHeight: 18.0];
      [tv setHeaderView: nil];
      [tv reloadData];

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 120)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[w contentView] addSubview: tv];

      /* Clicking a row selects it. */
      clickRow(w, tv, 2);
      PASS([tv selectedRow] == 2 && [tv numberOfSelectedRows] == 1,
        "clicking a row selects it");

      /* Clicking a different row moves the selection. */
      clickRow(w, tv, 4);
      PASS([tv selectedRow] == 4 && [tv numberOfSelectedRows] == 1,
        "clicking a different row moves the selection");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTableView click")

  DESTROY(arp);
  return 0;
}
