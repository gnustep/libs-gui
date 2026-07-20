/* NSTableView stores the grid style mask and keeps drawsGrid consistent with
   it, and stores allowsTypeSelect. Setting a non-empty mask makes drawsGrid
   YES; the none mask makes it NO; setDrawsGrid: YES sets the solid vertical and
   horizontal mask and NO clears it. The relationships were checked against
   AppKit on a macOS runner. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSTableView.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSTableView *tv;

  START_SET("NSTableView gridStyle")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 200, 200)]);

      [tv setGridStyleMask: NSTableViewSolidHorizontalGridLineMask];
      pass([tv gridStyleMask] == NSTableViewSolidHorizontalGridLineMask,
           "gridStyleMask round-trips");
      pass([tv drawsGrid] == YES, "a non-empty grid mask means drawsGrid is YES");

      [tv setGridStyleMask: NSTableViewGridNone];
      pass([tv drawsGrid] == NO, "the none grid mask means drawsGrid is NO");

      [tv setDrawsGrid: YES];
      pass([tv gridStyleMask] == (NSTableViewSolidVerticalGridLineMask
                                  | NSTableViewSolidHorizontalGridLineMask),
           "setDrawsGrid: YES sets the solid vertical and horizontal mask");
      [tv setDrawsGrid: NO];
      pass([tv gridStyleMask] == NSTableViewGridNone,
           "setDrawsGrid: NO clears the grid mask");

      pass([tv allowsTypeSelect] == YES, "type select is allowed by default");
      [tv setAllowsTypeSelect: NO];
      pass([tv allowsTypeSelect] == NO, "allowsTypeSelect round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTableView gridStyle")

  DESTROY(arp);
  return 0;
}
