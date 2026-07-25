/* NSArrayController initial-state defaults: a new controller avoids an empty
   selection, preserves the selection and clears the filter predicate on
   insertion, and an empty controller reports no selection index (NSNotFound)
   and an empty selected-objects array rather than raising.  Matches AppKit
   (verified on a macOS runner). */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSArrayController.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSArrayController *ac;

  ac = AUTORELEASE([[NSArrayController alloc] init]);

  PASS([ac avoidsEmptySelection] == YES,
       "default avoidsEmptySelection is YES");
  PASS([ac preservesSelection] == YES,
       "default preservesSelection is YES");
  PASS([ac clearsFilterPredicateOnInsertion] == YES,
       "default clearsFilterPredicateOnInsertion is YES");

  PASS([ac selectionIndex] == NSNotFound,
       "an empty controller has no selection index");
  PASS([[ac selectedObjects] count] == 0,
       "an empty controller has an empty selected-objects array");

  DESTROY(arp);
  return 0;
}
