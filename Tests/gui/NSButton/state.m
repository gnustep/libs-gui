/* Coverage for NSButton state and configuration: the defaults (off state, the
   "Button" title, bordered, not transparent, no mixed state, no image, no key
   equivalent), the setter round-trips and the off/on cycling of setNextState.
   Checked against AppKit on a macOS runner (image position is compared by its
   enumerated name).  The button uses the theme and font backend, so the set is
   skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSButton *b;

  START_SET("NSButton state")

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
      b = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 24)]);

      /* Defaults. */
      PASS([b state] == NSOffState, "a button is off by default");
      PASS([[b title] isEqualToString: @"Button"],
           "the default title is Button");
      PASS([b isBordered] == YES, "a button is bordered by default");
      PASS([b isTransparent] == NO, "a button is not transparent by default");
      PASS([b allowsMixedState] == NO, "mixed state is off by default");
      PASS([b imagePosition] == NSNoImage, "there is no image by default");
      PASS([[b keyEquivalent] isEqualToString: @""],
           "there is no key equivalent by default");

      /* Round-trips. */
      [b setState: NSOnState];
      PASS([b state] == NSOnState, "setState: round trips");
      [b setTitle: @"OK"];
      PASS([[b title] isEqualToString: @"OK"], "setTitle: round trips");
      [b setBordered: NO];
      PASS([b isBordered] == NO, "setBordered: round trips");
      [b setTransparent: YES];
      PASS([b isTransparent] == YES, "setTransparent: round trips");
      [b setImagePosition: NSImageLeft];
      PASS([b imagePosition] == NSImageLeft, "setImagePosition: round trips");
      [b setKeyEquivalent: @"x"];
      PASS([[b keyEquivalent] isEqualToString: @"x"],
           "setKeyEquivalent: round trips");
      [b setAllowsMixedState: YES];
      PASS([b allowsMixedState] == YES, "setAllowsMixedState: round trips");

      /* setNextState cycles off and on. */
      NSButton *b2 = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 24)]);
      [b2 setState: NSOffState];
      [b2 setNextState];
      PASS([b2 state] == NSOnState, "setNextState turns an off button on");
      [b2 setNextState];
      PASS([b2 state] == NSOffState, "setNextState turns an on button off");
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

  END_SET("NSButton state")

  DESTROY(arp);
  return 0;
}
