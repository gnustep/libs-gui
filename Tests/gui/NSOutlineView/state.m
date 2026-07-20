/* Coverage for NSOutlineView scalar state: the indentation-marker, autosave
   and outline-column defaults, and the indentation / marker / autosave
   round-trips. The indentationPerLevel default value is theme dependent and is
   only round-tripped. Checked against AppKit on a macOS runner; all pass on
   unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSOutlineView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSOutlineView *ov;

  START_SET("NSOutlineView state")

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

      pass([ov indentationMarkerFollowsCell] == YES,
           "the indentation marker follows the cell by default");
      pass([ov autosaveExpandedItems] == NO,
           "expanded items are not autosaved by default");
      pass([ov outlineTableColumn] == nil,
           "the outline table column is nil by default");

      [ov setIndentationPerLevel: 24.0];
      pass([ov indentationPerLevel] == 24.0, "indentationPerLevel round-trips");
      [ov setIndentationMarkerFollowsCell: NO];
      pass([ov indentationMarkerFollowsCell] == NO,
           "indentationMarkerFollowsCell round-trips");
      [ov setAutosaveExpandedItems: YES];
      pass([ov autosaveExpandedItems] == YES,
           "autosaveExpandedItems round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOutlineView state")

  DESTROY(arp);
  return 0;
}
