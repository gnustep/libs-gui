/* Coverage for NSMatrix scalar state: the intercell spacing, background and
   selection-by-rect defaults and their round-trips, plus the empty counts and
   no-selection start. Checked against AppKit on a macOS runner; the passing
   assertions hold on unmodified GNUstep. The PROBE lines report the AppKit
   defaults that may diverge on GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSMatrix.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSMatrix *m;

  START_SET("NSMatrix state")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      m = AUTORELEASE([[NSMatrix alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);

      /* matching defaults */
      PASS([m mode] == NSRadioModeMatrix, "the default mode is radio");
      {
        NSSize s = [m intercellSpacing];
        PASS(s.width == 1 && s.height == 1, "the default intercell spacing is 1x1");
      }
      PASS([m drawsBackground] == NO, "a matrix does not draw its background by default");
      PASS([m drawsCellBackground] == NO,
           "a matrix does not draw its cell background by default");
      PASS([m isSelectionByRect] == YES, "selection by rect is on by default");
      PASS([m numberOfRows] == 0, "a new matrix has no rows");
      PASS([m numberOfColumns] == 0, "a new matrix has no columns");
      PASS([m selectedRow] == -1, "no row is selected by default");
      PASS([m selectedColumn] == -1, "no column is selected by default");
      PASS([m allowsEmptySelection] == NO,
           "empty selection is not allowed by default");

      /* round-trips */
      [m setMode: NSListModeMatrix];
      PASS([m mode] == NSListModeMatrix, "mode round-trips");
      [m setSelectionByRect: NO];
      PASS([m isSelectionByRect] == NO, "selectionByRect round-trips");
      [m setDrawsBackground: YES];
      PASS([m drawsBackground] == YES, "drawsBackground round-trips");
      [m setIntercellSpacing: NSMakeSize(4, 6)];
      {
        NSSize s = [m intercellSpacing];
        PASS(s.width == 4 && s.height == 6, "intercellSpacing round-trips");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSMatrix state")

  DESTROY(arp);
  return 0;
}
