/*
copyright 2005 Alexander Malmberg <alexander@malmberg.org>
*/

#include "Testing.h"

#include <AppKit/NSApplication.h>
#include <AppKit/NSPopUpButton.h>

int main(int argc, char **argv)
{
  ENTER_POOL
  NSPopUpButton *b;

  START_SET("NSPopupButton GNUstep defaultSelection")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException ])
	SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  b = AUTORELEASE([[NSPopUpButton alloc] init]);

  [b addItemWithTitle: @"foo"];
  [b addItemWithTitle: @"bar"];

  PASS([b indexOfSelectedItem] == 0,"first item is selected by default");

  END_SET("NSPopupButton GNUstep defaultSelection")

  LEAVE_POOL

  return 0;
}

