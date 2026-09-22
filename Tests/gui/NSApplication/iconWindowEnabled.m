/* The application icon window is created only when the GSEnableAppIcon
   default is set.  A separate process is needed for each setting, so this
   test forces the default on and iconWindow.m forces it off.  The
   default is placed in the argument domain so that a value in the user's
   own defaults cannot change the outcome.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSWindow.h>

int
main(int argc, char **argv)
{
  NSAutoreleasePool	*arp = [NSAutoreleasePool new];
  NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary	*args;

  args = [[[defs volatileDomainForName: NSArgumentDomain] mutableCopy]
    autorelease];
  [args setObject: @"YES" forKey: @"GSEnableAppIcon"];
  [defs removeVolatileDomainForName: NSArgumentDomain];
  [defs setVolatileDomain: args forName: NSArgumentDomain];

  START_SET("NSApplication icon window when enabled")

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

  PASS([NSApp iconWindow] != nil,
    "an icon window is created when GSEnableAppIcon is YES")

  END_SET("NSApplication icon window when enabled")

  [arp release];
  return 0;
}
