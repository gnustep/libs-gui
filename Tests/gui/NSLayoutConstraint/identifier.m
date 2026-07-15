/* NSLayoutConstraint has an identifier that defaults to nil and round-trips
   through -setIdentifier:, as AppKit does. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSString.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSView.h>
#include <AppKit/NSLayoutConstraint.h>

@interface NSLayoutConstraint (Compat)
- (NSString *) identifier;
- (void) setIdentifier: (NSString *)identifier;
@end

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSView *v1, *v2;
  NSLayoutConstraint *c;

  START_SET("NSLayoutConstraint identifier")

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
  pass([c respondsToSelector: @selector(identifier)], "responds to -identifier");
  pass([c respondsToSelector: @selector(setIdentifier:)],
       "responds to -setIdentifier:");
  if ([c respondsToSelector: @selector(setIdentifier:)])
    {
      pass([c identifier] == nil, "default identifier is nil");
      [c setIdentifier: @"myC"];
      pass([[c identifier] isEqualToString: @"myC"], "identifier round-trips");
    }

  END_SET("NSLayoutConstraint identifier")

  DESTROY(arp);
  return 0;
}
