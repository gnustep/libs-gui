/* -[NSPathControl isEditable] defaults to YES and -setEditable: round-trips,
   matching AppKit. */
#import "Testing.h"
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSPathControl.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSPathControl editable")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSPathControl *pc =
      [[NSPathControl alloc] initWithFrame: NSMakeRect(0, 0, 200, 30)];

  PASS([pc isEditable] == YES, "-isEditable defaults to YES");

  [pc setEditable: NO];
  PASS([pc isEditable] == NO, "-setEditable: NO round-trips");

  [pc setEditable: YES];
  PASS([pc isEditable] == YES, "-setEditable: YES round-trips");

  RELEASE(pc);

  END_SET("NSPathControl editable")

  DESTROY(arp);
  return 0;
}
