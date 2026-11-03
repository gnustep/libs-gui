/* A new NSForm does not autosize its cells but does let the tab key traverse
   cells, unlike a plain NSMatrix.  Checked against AppKit on a macOS runner. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSForm.h>

int main()
{
  NSForm *f;

  START_SET("NSForm defaults")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      f = AUTORELEASE([[NSForm alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);

      PASS([f autosizesCells] == NO,
           "a new form does not autosize its cells");
      PASS([f tabKeyTraversesCells] == YES,
           "a new form lets the tab key traverse cells");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSForm defaults")

  return 0;
}
