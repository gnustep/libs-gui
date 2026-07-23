/* NSAnimation -progressMarks caches the NSNumber objects it returns and
   refreshes that cache when the marks change.  The cached numbers must be
   owned by the animation, otherwise refreshing the cache over-releases them.
   Calling -progressMarks repeatedly with a change between each call exercises
   the refresh. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAnimation.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSAnimation *a;
  NSArray *marks;

  a = AUTORELEASE([[NSAnimation alloc]
    initWithDuration: 1.0 animationCurve: NSAnimationLinear]);

  [a addProgressMark: 0.5];
  [a addProgressMark: 0.25];
  [a addProgressMark: 0.75];
  marks = [a progressMarks];
  PASS([marks count] == 3, "the first call reports three marks");

  [a removeProgressMark: 0.5];
  marks = [a progressMarks];
  PASS([marks count] == 2
    && [[marks objectAtIndex: 0] floatValue] == 0.25
    && [[marks objectAtIndex: 1] floatValue] == 0.75,
       "a call after a removal reports the remaining marks");

  [a addProgressMark: 0.875];
  marks = [a progressMarks];
  PASS([marks count] == 3
    && [[marks objectAtIndex: 2] floatValue] == 0.875,
       "a call after an addition reports the new set");

  DESTROY(arp);
  return 0;
}
