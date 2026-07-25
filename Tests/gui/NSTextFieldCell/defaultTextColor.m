/* A text field cell is a control, so its default text colour is the
   control text colour, as on OS X (its default text colour is
   controlTextColor, not the generic textColor). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSTextFieldCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSTextFieldCell default text colour")

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

  {
    NSTextFieldCell *cell = AUTORELEASE([[NSTextFieldCell alloc] initTextCell: @""]);

    PASS([[cell textColor] isEqual: [NSColor controlTextColor]],
      "the default text colour is the control text colour");
  }

  END_SET("NSTextFieldCell default text colour")

  DESTROY(arp);
  return 0;
}
