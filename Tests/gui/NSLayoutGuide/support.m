/* NSView layout-guide support: -addLayoutGuide: adds the guide and sets its
   owning view, -layoutGuides reports it, and -removeLayoutGuide: reverses both.
   Behaviour checked against AppKit on macOS. */
#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSLayoutGuide.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  START_SET("NSView layout guides")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NSView *v = AUTORELEASE([[NSView alloc]
                            initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  NSLayoutGuide *g = AUTORELEASE([[NSLayoutGuide alloc] init]);

  /* A view with no guides reports an empty (non-nil) array. */
  PASS([v layoutGuides] != nil, "-layoutGuides is not nil");
  PASS([[v layoutGuides] count] == 0, "-layoutGuides is empty by default");

  /* Adding a guide registers it and sets its owning view. */
  [v addLayoutGuide: g];
  PASS([g owningView] == v, "-addLayoutGuide: sets the guide's owningView");
  PASS([[v layoutGuides] containsObject: g],
       "-layoutGuides contains the added guide");
  PASS([[v layoutGuides] count] == 1, "one guide is registered");

  /* Adding the same guide again does not duplicate it. */
  [v addLayoutGuide: g];
  PASS([[v layoutGuides] count] == 1, "adding the same guide twice is a no-op");

  /* Removing the guide reverses both effects. */
  [v removeLayoutGuide: g];
  PASS([g owningView] == nil, "-removeLayoutGuide: clears the owningView");
  PASS([[v layoutGuides] count] == 0, "the guide is unregistered");

  END_SET("NSView layout guides")

  DESTROY(arp);
  return 0;
}
