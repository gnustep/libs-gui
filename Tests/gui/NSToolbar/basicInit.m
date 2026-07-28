/* -init creates a toolbar with an empty identifier, leaving it in the same
   state as one built with -initWithIdentifier:. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbar.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSToolbar *ref;
  NSToolbar *tb;

  START_SET("NSToolbar basic init")

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
      /* A toolbar built the long way, to compare the defaults against. Its
         identifier differs from the one -init uses, so it does not act as the
         configuration model for the toolbar built below. */
      ref = AUTORELEASE([[NSToolbar alloc] initWithIdentifier: @"reference"]);
      tb = AUTORELEASE([[NSToolbar alloc] init]);

      PASS([[tb identifier] isEqualToString: @""],
        "-init gives the toolbar an empty identifier");
      PASS([tb displayMode] == [ref displayMode],
        "-init leaves the display mode at its default");
      PASS([tb sizeMode] == [ref sizeMode],
        "-init leaves the size mode at its default");
      PASS([tb showsBaselineSeparator] == [ref showsBaselineSeparator],
        "-init leaves the baseline separator at its default");
      PASS([tb isVisible] == [ref isVisible],
        "-init leaves the toolbar visible by default");
      PASS([tb items] != nil && [[tb items] count] == 0,
        "-init starts the toolbar with an empty item list");
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

  END_SET("NSToolbar basic init")

  DESTROY(arp);
  return 0;
}
