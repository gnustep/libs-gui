/* Coverage for NSLayoutConstraint: the constraintWithItem:... factory and its
   readonly accessors (firstItem, firstAttribute, relation, secondItem,
   secondAttribute, multiplier, constant), the default priority and inactive
   state, and the priority setter.  Every assertion here matches AppKit
   (verified on a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSLayoutConstraint.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSView *v1, *v2;
  NSLayoutConstraint *c;

  START_SET("NSLayoutConstraint basic")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  v1 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)]);
  v2 = AUTORELEASE([[NSView alloc] initWithFrame: NSMakeRect(0, 0, 40, 40)]);
  [v1 addSubview: v2];

  c = [NSLayoutConstraint constraintWithItem: v1
                                   attribute: NSLayoutAttributeWidth
                                   relatedBy: NSLayoutRelationEqual
                                      toItem: v2
                                   attribute: NSLayoutAttributeWidth
                                  multiplier: 2.0
                                    constant: 5.0];
  pass(c != nil, "the factory returns a constraint");
  pass([c firstItem] == v1, "firstItem is the first item passed in");
  pass([c firstAttribute] == NSLayoutAttributeWidth,
       "firstAttribute is the attribute passed in");
  pass([c relation] == NSLayoutRelationEqual, "relation is the relation passed in");
  pass([c secondItem] == v2, "secondItem is the second item passed in");
  pass([c secondAttribute] == NSLayoutAttributeWidth,
       "secondAttribute is the attribute passed in");
  pass([c multiplier] == 2.0, "multiplier is the multiplier passed in");
  pass([c constant] == 5.0, "constant is the constant passed in");
  pass([c priority] == NSLayoutPriorityRequired,
       "a factory constraint has the required priority");
  pass([c isActive] == NO, "a factory constraint is inactive");

  [c setPriority: NSLayoutPriorityDefaultHigh];
  pass([c priority] == NSLayoutPriorityDefaultHigh, "priority round-trips");

  END_SET("NSLayoutConstraint basic")

  DESTROY(arp);
  return 0;
}
