#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSActionCell.h>

/* -setEnabled: only asks for display when the state changes: NSToolbarItem's
   -validate calls it after every event, whatever the state. */

int
main(int argc, const char **argv)
{
  START_SET("NSControl setEnabled: display")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  {
    NSControl *c = AUTORELEASE([[NSControl alloc]
      initWithFrame: NSMakeRect(0, 0, 100, 20)]);

    [c setCell: AUTORELEASE([[NSActionCell alloc] initTextCell: @""])];
    PASS([c isEnabled], "a new control is enabled");

    [c setNeedsDisplay: NO];
    [c setEnabled: YES];
    PASS([c needsDisplay] == NO, "enabling an enabled control asks for no display");
    PASS([c isEnabled], "and it stays enabled");

    [c setEnabled: NO];
    PASS([c needsDisplay], "disabling it asks for display");
    PASS([c isEnabled] == NO, "and it is disabled");

    [c setNeedsDisplay: NO];
    [c setEnabled: NO];
    PASS([c needsDisplay] == NO, "disabling a disabled control asks for no display");
    PASS([c isEnabled] == NO, "and it stays disabled");

    [c setEnabled: YES];
    PASS([c needsDisplay], "enabling it asks for display");
    PASS([c isEnabled], "and it is enabled");
  }

  END_SET("NSControl setEnabled: display")
  return 0;
}
