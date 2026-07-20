/* NSMatrix stores a tool tip per cell: -setToolTip:forCell: records it,
   -toolTipForCell: returns it (nil when none is set), and a nil tool tip
   clears it. Checked against AppKit on a macOS runner. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSMatrix *m;
  NSCell *c0, *c1;

  START_SET("NSMatrix toolTips")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      m = AUTORELEASE([[NSMatrix alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)
                 mode: NSListModeMatrix
            prototype: AUTORELEASE([[NSCell alloc] initTextCell: @"x"])
         numberOfRows: 1
      numberOfColumns: 2]);
      c0 = [m cellAtRow: 0 column: 0];
      c1 = [m cellAtRow: 0 column: 1];

      pass([m toolTipForCell: c0] == nil,
           "a cell with no tool tip returns nil");

      [m setToolTip: @"hello" forCell: c0];
      pass([[m toolTipForCell: c0] isEqualToString: @"hello"],
           "setToolTip:forCell: records the tool tip");
      pass([m toolTipForCell: c1] == nil,
           "another cell still has no tool tip");

      [m setToolTip: nil forCell: c0];
      pass([m toolTipForCell: c0] == nil, "a nil tool tip clears the cell");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMatrix toolTips")

  DESTROY(arp);
  return 0;
}
