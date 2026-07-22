/* Coverage for NSActionCell: init defaults (tag, target, action, controlView,
   enabled, bordered, bezeled), the tag/target/action setters, the bezel/border
   mutual exclusion, and setEnabled:.  Every assertion was checked against Apple
   AppKit (macOS 26) and matches.  Creating the cell pulls in the default font,
   which needs the backend, so the body is guarded. */
#import "Testing.h"
#import <Foundation/NSObject.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSActionCell.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSActionCell basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSActionCell *c = [[NSActionCell alloc] init];
  PASS(c != nil, "NSActionCell -init returns an instance");

  /* Defaults that match AppKit. */
  PASS([c tag] == 0, "default tag is 0");
  PASS([c target] == nil, "default target is nil");
  PASS([c action] == NULL, "default action is NULL");
  PASS([c controlView] == nil, "default controlView is nil");
  PASS([c isEnabled] == YES, "default isEnabled is YES");
  PASS([c isBordered] == NO, "default isBordered is NO");
  PASS([c isBezeled] == NO, "default isBezeled is NO");

  /* tag / target / action setters. */
  [c setTag: 42];
  PASS([c tag] == 42, "setTag: round-trips");

  id t = AUTORELEASE([NSObject new]);
  [c setTarget: t];
  PASS([c target] == t, "setTarget: keeps the same object (not retained-copy)");

  [c setAction: @selector(fire:)];
  PASS([NSStringFromSelector([c action]) isEqualToString: @"fire:"],
       "setAction: round-trips");

  /* Bezel and border are mutually exclusive, matching AppKit. */
  [c setBezeled: YES];
  PASS([c isBezeled] == YES, "setBezeled: YES sets isBezeled");
  PASS([c isBordered] == NO, "setBezeled: YES clears isBordered");

  [c setBordered: YES];
  PASS([c isBordered] == YES, "setBordered: YES sets isBordered");
  PASS([c isBezeled] == NO, "setBordered: YES clears isBezeled");

  /* Enabled. */
  [c setEnabled: NO];
  PASS([c isEnabled] == NO, "setEnabled: NO round-trips");

  RELEASE(c);

  END_SET("NSActionCell basic")

  DESTROY(arp);
  return 0;
}
