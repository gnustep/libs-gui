/* -[NSPathControl pathItems] returns an empty array (not nil) for a control
   with no items, matching AppKit. */
#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSPathControl.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSPathControl pathItems")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSPathControl *pc =
      [[NSPathControl alloc] initWithFrame: NSMakeRect(0, 0, 200, 30)];

  PASS([pc pathItems] != nil, "-pathItems is not nil for an empty control");
  PASS([[pc pathItems] count] == 0, "-pathItems is empty for an empty control");

  RELEASE(pc);

  END_SET("NSPathControl pathItems")

  DESTROY(arp);
  return 0;
}
