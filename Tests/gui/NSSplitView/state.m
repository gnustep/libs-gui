/* Coverage for NSSplitView scalar state: the orientation, divider style,
   divider colour, autosave name and delegate defaults and round-trips. The
   AppKit-comparable assertions were checked on a macOS runner; the pane
   splitter flag is a GNUstep extension and is only round-tripped. All pass on
   unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSSplitView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSplitView *sv;

  START_SET("NSSplitView state")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      sv = AUTORELEASE([[NSSplitView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 100)]);

      pass([sv isVertical] == NO, "a split view is horizontal by default");
      pass([sv dividerStyle] == NSSplitViewDividerStyleThick,
           "the default divider style is thick");
      pass([sv dividerColor] != nil, "a split view has a divider colour");
      pass([sv autosaveName] == nil, "the default autosave name is nil");
      pass([sv delegate] == nil, "the default delegate is nil");

      [sv setVertical: YES];
      pass([sv isVertical] == YES, "isVertical round-trips");
      [sv setDividerStyle: NSSplitViewDividerStyleThin];
      pass([sv dividerStyle] == NSSplitViewDividerStyleThin,
           "dividerStyle round-trips to thin");
      [sv setDividerStyle: NSSplitViewDividerStylePaneSplitter];
      pass([sv dividerStyle] == NSSplitViewDividerStylePaneSplitter,
           "dividerStyle round-trips to pane splitter");
      [sv setAutosaveName: @"mySplit"];
      pass([[sv autosaveName] isEqualToString: @"mySplit"],
           "autosaveName round-trips");

      /* isPaneSplitter is a GNUstep extension */
      [sv setIsPaneSplitter: NO];
      pass([sv isPaneSplitter] == NO, "isPaneSplitter round-trips to NO");
      [sv setIsPaneSplitter: YES];
      pass([sv isPaneSplitter] == YES, "isPaneSplitter round-trips to YES");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSSplitView state")

  DESTROY(arp);
  return 0;
}
