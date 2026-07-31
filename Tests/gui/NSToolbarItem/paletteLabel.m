/* A default NSToolbarItem paletteLabel is the empty string, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbarItem.h>

int main()
{
  NSToolbarItem *item;

  START_SET("NSToolbarItem paletteLabel")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  item = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: @"p"]);
  PASS([[item paletteLabel] isEqualToString: @""],
       "default paletteLabel is the empty string");

  END_SET("NSToolbarItem paletteLabel")

  return 0;
}
