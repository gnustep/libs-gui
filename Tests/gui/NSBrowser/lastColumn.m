/* The browser tells its delegate when the last loaded column changes, which
   is how a delegate keeps track of how far the browser has been walked. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSMatrix.h>

@interface ColumnWatcher : NSObject
{
@public
  NSInteger calls;
  NSInteger lastOld;
  NSInteger lastNew;
}
@end

@implementation ColumnWatcher
- (NSInteger) browser: (NSBrowser *)sender numberOfRowsInColumn: (NSInteger)column
{
  return 3;
}
- (void) browser: (NSBrowser *)sender
 willDisplayCell: (id)cell
	   atRow: (NSInteger)row
	  column: (NSInteger)column
{
  [cell setStringValue: @"row"];
  [cell setLeaf: (column > 1)];
}
- (void) browser: (NSBrowser *)browser
didChangeLastColumn: (NSInteger)oldLastColumn
	toColumn: (NSInteger)column
{
  calls++;
  lastOld = oldLastColumn;
  lastNew = column;
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSBrowser *browser;
  ColumnWatcher *watcher;

  START_SET("NSBrowser last column delegate method")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      watcher = AUTORELEASE([[ColumnWatcher alloc] init]);
      browser = AUTORELEASE([[NSBrowser alloc]
	initWithFrame: NSMakeRect(0, 0, 400, 200)]);
      [browser setDelegate: watcher];
      [browser loadColumnZero];

      PASS(watcher->calls == 1,
	"loading column zero tells the delegate the last column changed");
      PASS(watcher->lastOld == -1 && watcher->lastNew == 0,
	"loading column zero reports the move from nothing to column zero");

      watcher->calls = 0;
      [browser setLastColumn: 0];
      PASS(watcher->calls == 0,
	"setting the last column to what it already is says nothing");

      [browser addColumn];
      PASS(watcher->calls > 0,
	"loading another column tells the delegate the last column changed");
      PASS(watcher->lastNew == [browser lastColumn],
	"the delegate is told the column the browser ended up on");

      watcher->calls = 0;
      watcher->lastOld = -99;
      [browser setLastColumn: 0];
      PASS(watcher->calls == 1,
	"unloading back to column zero tells the delegate once");
      PASS(watcher->lastOld == 1 && watcher->lastNew == 0,
	"the delegate is told which column it moved from and to");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSBrowser last column delegate method")

  DESTROY(arp);

  return 0;
}
