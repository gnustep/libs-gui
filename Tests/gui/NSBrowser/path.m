/* -[NSBrowser path] names the columns up to the selection.  When a branch is
   selected its child column is loaded but nothing in it is selected yet, so
   the path ends at the branch with no trailing separator; once a row in the
   child column is selected the path names both.  Checked against AppKit on a
   macOS runner.  The browser uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>

@interface BrowserContent : NSObject
@end

@implementation BrowserContent
- (NSInteger) browser: (NSBrowser *)sender numberOfRowsInColumn: (NSInteger)column
{
  if (column == 0) return 3;
  if (column == 1) return 2;
  return 0;
}
- (void) browser: (NSBrowser *)sender
  willDisplayCell: (id)cell
            atRow: (NSInteger)row
           column: (NSInteger)column
{
  if (column == 0)
    {
      [cell setStringValue: [NSString stringWithFormat: @"c0r%ld", (long)row]];
      [cell setLeaf: (row == 2)];
    }
  else
    {
      [cell setStringValue: [NSString stringWithFormat: @"c1r%ld", (long)row]];
      [cell setLeaf: YES];
    }
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSBrowser *browser;
  BrowserContent *content;

  START_SET("NSBrowser path")

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
      content = AUTORELEASE([BrowserContent new]);
      browser = AUTORELEASE([[NSBrowser alloc]
        initWithFrame: NSMakeRect(0, 0, 300, 200)]);
      [browser setDelegate: content];
      [browser loadColumnZero];

      [browser selectRow: 0 inColumn: 0];
      pass([[browser path] isEqualToString: @"/c0r0"],
           "a selected branch ends the path with no trailing separator");

      [browser selectRow: 0 inColumn: 1];
      pass([[browser path] isEqualToString: @"/c0r0/c1r0"],
           "a selected leaf extends the path with its branch");
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

  END_SET("NSBrowser path")

  DESTROY(arp);
  return 0;
}
