/* Coverage for NSArrayController defaults and behavior-flag round-trips: a new
   controller selects inserted objects, does not use the multiple-values marker,
   does not automatically rearrange, and starts with no arranged objects, no
   selection, no sort descriptors and no filter predicate.  Every assertion here
   matches AppKit (verified on a macOS runner) and passes on unmodified
   GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSIndexSet.h>

#include <AppKit/NSArrayController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSArrayController *ac;

  ac = AUTORELEASE([[NSArrayController alloc] init]);

  PASS([ac selectsInsertedObjects] == YES,
       "default selectsInsertedObjects is YES");
  PASS([ac alwaysUsesMultipleValuesMarker] == NO,
       "default alwaysUsesMultipleValuesMarker is NO");
  PASS([ac automaticallyRearrangesObjects] == NO,
       "default automaticallyRearrangesObjects is NO");
  PASS([[ac arrangedObjects] count] == 0,
       "a new controller has no arranged objects");
  PASS([[ac selectionIndexes] count] == 0,
       "a new controller has an empty selection");
  PASS([ac sortDescriptors] == nil || [[ac sortDescriptors] count] == 0,
       "a new controller has no sort descriptors");
  PASS([ac filterPredicate] == nil,
       "a new controller has no filter predicate");

  [ac setSelectsInsertedObjects: NO];
  PASS([ac selectsInsertedObjects] == NO, "selectsInsertedObjects round-trips");
  [ac setAvoidsEmptySelection: YES];
  PASS([ac avoidsEmptySelection] == YES, "avoidsEmptySelection round-trips");
  [ac setPreservesSelection: NO];
  PASS([ac preservesSelection] == NO, "preservesSelection round-trips");
  [ac setAlwaysUsesMultipleValuesMarker: YES];
  PASS([ac alwaysUsesMultipleValuesMarker] == YES,
       "alwaysUsesMultipleValuesMarker round-trips");
  [ac setClearsFilterPredicateOnInsertion: YES];
  PASS([ac clearsFilterPredicateOnInsertion] == YES,
       "clearsFilterPredicateOnInsertion round-trips");
  [ac setAutomaticallyRearrangesObjects: YES];
  PASS([ac automaticallyRearrangesObjects] == YES,
       "automaticallyRearrangesObjects round-trips");

  DESTROY(arp);
  return 0;
}
