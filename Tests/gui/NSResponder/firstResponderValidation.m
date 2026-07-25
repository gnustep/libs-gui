#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <AppKit/NSResponder.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSResponder first responder validation")

  NSResponder *r = AUTORELEASE([NSResponder new]);
  NSResponder *other = AUTORELEASE([NSResponder new]);

  /* The default implementations accept the proposed first responder and
     supply no alternate action target.  Checked against AppKit. */
  PASS([r validateProposedFirstResponder: other forEvent: nil] == YES,
    "validateProposedFirstResponder:forEvent: returns YES by default");

  PASS([r supplementalTargetForAction: @selector(copy:) sender: nil] == nil,
    "supplementalTargetForAction:sender: returns nil by default");

  END_SET("NSResponder first responder validation")
  DESTROY(arp);
  return 0;
}
