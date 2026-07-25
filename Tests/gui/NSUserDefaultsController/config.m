/* Coverage for NSUserDefaultsController: the shared controller is a singleton
   that applies immediately, uses the standard user defaults, has a values
   proxy, no unapplied changes and no initial values; a controller created with
   nil defaults uses the standard defaults; and appliesImmediately and the
   initial values round-trip.  Every assertion here matches AppKit (verified on
   a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>

#include <AppKit/NSUserDefaultsController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSUserDefaultsController *shared;
  NSUserDefaultsController *c;

  shared = [NSUserDefaultsController sharedUserDefaultsController];
  PASS(shared != nil, "the shared controller exists");
  PASS(shared == [NSUserDefaultsController sharedUserDefaultsController],
       "the shared controller is a singleton");
  PASS([shared appliesImmediately] == YES,
       "the shared controller applies immediately");
  PASS([shared defaults] != nil, "the shared controller has defaults");
  PASS([shared defaults] == [NSUserDefaults standardUserDefaults],
       "the shared controller uses the standard user defaults");
  PASS([shared values] != nil, "the shared controller has a values proxy");
  PASS([shared hasUnappliedChanges] == NO,
       "the shared controller has no unapplied changes");
  PASS([shared initialValues] == nil || [[shared initialValues] count] == 0,
       "the shared controller has no initial values");

  c = AUTORELEASE([[NSUserDefaultsController alloc]
    initWithDefaults: nil initialValues: nil]);
  PASS([c defaults] == [NSUserDefaults standardUserDefaults],
       "a controller with nil defaults uses the standard user defaults");
  PASS([c appliesImmediately] == YES, "default appliesImmediately is YES");
  PASS([c values] != nil, "the controller has a values proxy");

  [c setAppliesImmediately: NO];
  PASS([c appliesImmediately] == NO, "appliesImmediately round-trips");
  [c setInitialValues: [NSDictionary dictionaryWithObject: @"v" forKey: @"k"]];
  PASS([[c initialValues] count] == 1, "initialValues round-trips");

  DESTROY(arp);
  return 0;
}
