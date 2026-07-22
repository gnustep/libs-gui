/* NSLayoutConstraint -shouldBeArchived defaults to NO and round-trips through
   -setShouldBeArchived:, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSLayoutConstraint.h>

@interface NSLayoutConstraint (Compat)
- (BOOL) shouldBeArchived;
- (void) setShouldBeArchived: (BOOL)flag;
@end

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSView *v1, *v2;
  NSLayoutConstraint *c;

  START_SET("NSLayoutConstraint shouldBeArchived")

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
  PASS([c respondsToSelector: @selector(shouldBeArchived)],
       "responds to -shouldBeArchived");
  if ([c respondsToSelector: @selector(shouldBeArchived)])
    {
      PASS([c shouldBeArchived] == NO, "default shouldBeArchived is NO");
      [c setShouldBeArchived: YES];
      PASS([c shouldBeArchived] == YES, "shouldBeArchived round-trips");
    }

  END_SET("NSLayoutConstraint shouldBeArchived")

  DESTROY(arp);
  return 0;
}
