/* NSLayoutConstraint -setConstant: changes the constant, as AppKit allows. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSLayoutConstraint.h>

/* Declared so the test compiles whether or not the setter is present yet; the
   respondsToSelector: check is what actually verifies it. */
@interface NSLayoutConstraint (Compat)
- (void) setConstant: (CGFloat)constant;
@end

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSView *v1, *v2;
  NSLayoutConstraint *c;

  START_SET("NSLayoutConstraint setConstant")

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
                                  multiplier: 1.0
                                    constant: 5.0];
  pass([c respondsToSelector: @selector(setConstant:)], "responds to -setConstant:");
  if ([c respondsToSelector: @selector(setConstant:)])
    {
      [c setConstant: 42.0];
      pass([c constant] == 42.0, "-setConstant: changes the constant");
    }

  END_SET("NSLayoutConstraint setConstant")

  DESTROY(arp);
  return 0;
}
