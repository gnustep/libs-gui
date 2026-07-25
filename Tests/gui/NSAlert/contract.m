/* Coverage for the NSAlert button contract: -addButtonWithTitle: appends the
   button in order and hands back the same button that appears in -buttons,
   each button's tag is the return code its click will produce
   (NSAlertFirstButtonReturn, then Second, then Third), the message and
   informative text round-trip, and a new alert is a warning by default.
   Checked against AppKit on a macOS runner.  Building the alert's buttons
   touches the font/graphics backend, so the set is skipped when the backend is
   unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAlert.h>
#include <AppKit/NSButton.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSAlert *a;

  START_SET("NSAlert contract")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSButton *b0, *b1, *b2;
      NSArray *buttons;

      a = AUTORELEASE([[NSAlert alloc] init]);
      [a setMessageText: @"The message"];
      [a setInformativeText: @"More detail"];

      PASS([a alertStyle] == NSWarningAlertStyle,
        "a new alert is a warning by default");
      PASS([[a messageText] isEqual: @"The message"], "the message round-trips");
      PASS([[a informativeText] isEqual: @"More detail"],
        "the informative text round-trips");

      b0 = [a addButtonWithTitle: @"OK"];
      b1 = [a addButtonWithTitle: @"Cancel"];
      b2 = [a addButtonWithTitle: @"Maybe"];
      buttons = [a buttons];

      PASS([buttons count] == 3, "the three buttons are added");
      PASS(b0 == [buttons objectAtIndex: 0]
        && b1 == [buttons objectAtIndex: 1]
        && b2 == [buttons objectAtIndex: 2],
        "addButtonWithTitle: returns the button in order");

      /* Each button's tag is the code its click produces. */
      PASS([b0 tag] == NSAlertFirstButtonReturn,
        "the first button returns NSAlertFirstButtonReturn");
      PASS([b1 tag] == NSAlertSecondButtonReturn,
        "the second button returns NSAlertSecondButtonReturn");
      PASS([b2 tag] == NSAlertThirdButtonReturn,
        "the third button returns NSAlertThirdButtonReturn");

      /* The key equivalents let Return trigger the first (default) button and
         Escape the Cancel button; another button has none. */
      PASS([[b0 keyEquivalent] isEqual: @"\r"],
        "the first button answers to Return");
      PASS([[b1 keyEquivalent] isEqual: @"\033"],
        "the Cancel button answers to Escape");
      PASS([[b2 keyEquivalent] length] == 0,
        "another button has no key equivalent");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSAlert contract")

  DESTROY(arp);
  return 0;
}
