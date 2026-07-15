/* -[NSLayoutAnchor constraintEqualToAnchor:constant:] carries the constant
   through to the resulting constraint, matching AppKit and its own
   greater-than / less-than siblings. */
#import "Testing.h"
#import <AppKit/NSLayoutAnchor.h>
#import <AppKit/NSLayoutConstraint.h>

int main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);

  NSLayoutAnchor *a = AUTORELEASE([[NSLayoutAnchor alloc] init]);

  NSLayoutConstraint *e = [a constraintEqualToAnchor: a constant: 10.0];
  PASS([e constant] == 10.0,
       "constraintEqualToAnchor:constant: carries the constant");

  /* The greater-/less-than variants already carry it; check for parity. */
  NSLayoutConstraint *g = [a constraintGreaterThanOrEqualToAnchor: a
                                                         constant: 10.0];
  PASS([g constant] == 10.0,
       "constraintGreaterThanOrEqualToAnchor:constant: carries the constant");

  DESTROY(arp);
  return 0;
}
