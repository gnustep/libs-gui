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
      pass([b state] == NSOffState, "a button is off by default");
      pass([[b title] isEqualToString: @"Button"],
           "the default title is Button");
      pass([b isBordered] == YES, "a button is bordered by default");
      pass([b isTransparent] == NO, "a button is not transparent by default");
      pass([b allowsMixedState] == NO, "mixed state is off by default");
      pass([b imagePosition] == NSNoImage, "there is no image by default");
      pass([[b keyEquivalent] isEqualToString: @""],
           "there is no key equivalent by default");

      /* Round-trips. */
      [b setState: NSOnState];
      pass([b state] == NSOnState, "setState: round trips");
      [b setTitle: @"OK"];
      pass([[b title] isEqualToString: @"OK"], "setTitle: round trips");
      [b setBordered: NO];
      pass([b isBordered] == NO, "setBordered: round trips");
      [b setTransparent: YES];
      pass([b isTransparent] == YES, "setTransparent: round trips");
      [b setImagePosition: NSImageLeft];
      pass([b imagePosition] == NSImageLeft, "setImagePosition: round trips");
      [b setKeyEquivalent: @"x"];
      pass([[b keyEquivalent] isEqualToString: @"x"],
           "setKeyEquivalent: round trips");
      [b setAllowsMixedState: YES];
      pass([b allowsMixedState] == YES, "setAllowsMixedState: round trips");

      /* setNextState cycles off and on. */
      NSButton *b2 = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 24)]);
      [b2 setState: NSOffState];
      [b2 setNextState];
      pass([b2 state] == NSOnState, "setNextState turns an off button on");
      [b2 setNextState];
      pass([b2 state] == NSOffState, "setNextState turns an on button off");
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
