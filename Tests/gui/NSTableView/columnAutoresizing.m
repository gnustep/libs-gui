/* -setColumnAutoresizingStyle: and -columnAutoresizingStyle used to be
   stubs: a table decoded from a nib dropped the style the nib gave it, and
   so never followed the width of the scroll view it sat in.  The style is
   kept now, and a change to the enclosing view's frame sizes the columns
   the way the style says.  No event loop is needed - the resize is driven
   directly - but the set keeps the usual backend guard, since building a
   table touches the graphics backend. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableView.h>

int
main(int argc, const char **argv)
{
  NSTableView		*table;
  NSScrollView		*scroll;
  NSTableColumn		*first;
  NSTableColumn		*second;
  CGFloat		widthBefore;
  CGFloat		totalAfter;

  START_SET("NSTableView columnAutoresizingStyle")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      table = AUTORELEASE([[NSTableView alloc]
	initWithFrame: NSMakeRect(0, 0, 100, 100)]);

      first = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"a"]);
      second = AUTORELEASE([[NSTableColumn alloc] initWithIdentifier: @"b"]);
      [first setWidth: 50.0];
      [second setWidth: 50.0];
      [first setMinWidth: 10.0];
      [second setMinWidth: 10.0];
      [first setMaxWidth: 1000.0];
      [second setMaxWidth: 1000.0];
      [table addTableColumn: first];
      [table addTableColumn: second];

      /* The style is kept rather than dropped. */
      [table setColumnAutoresizingStyle: NSTableViewUniformColumnAutoresizingStyle];
      PASS([table columnAutoresizingStyle]
	== NSTableViewUniformColumnAutoresizingStyle,
	"a table keeps the column autoresizing style it is given");

      [table setColumnAutoresizingStyle: NSTableViewLastColumnOnlyAutoresizingStyle];
      PASS([table columnAutoresizingStyle]
	== NSTableViewLastColumnOnlyAutoresizingStyle,
	"a table keeps a second style it is given");

      /* And acts on it: widening the enclosing view widens the columns,
         which for this style means the last one.  The two width
         assertions below also hold under the older heuristic, which
         tracked a table that happened to be exactly as wide as its clip
         view; it is the two above that tell the styles apart. */
      scroll = AUTORELEASE([[NSScrollView alloc]
	initWithFrame: NSMakeRect(0, 0, 100, 100)]);
      [scroll setDocumentView: table];

      widthBefore = [second width];
      [scroll setFrameSize: NSMakeSize(300, 100)];

      PASS([second width] > widthBefore,
	"the last column grows when the enclosing view does");

      totalAfter = [first width] + [second width];
      PASS(totalAfter > 100.0,
	"the columns together follow the width they are given");

      /* A control: the style the table has by default leaves the columns
         where they are, so the behaviour above is the style's doing. */
      [table setColumnAutoresizingStyle: NSTableViewNoColumnAutoresizing];
      PASS([table columnAutoresizingStyle] == NSTableViewNoColumnAutoresizing,
	"a table can be told to autoresize no columns at all");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTableView columnAutoresizingStyle")

  return 0;
}
