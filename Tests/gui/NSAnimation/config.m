/* Coverage for NSAnimation default state and the curve and blocking-mode enum
   values.  A new animation reports the duration and curve it was created with,
   the default-in-out curve, a blocking run mode, no progress, no marks and no
   delegate, and is not animating.  Every assertion here matches AppKit
   (verified on a macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAnimation.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSAnimation *a;

  PASS(NSAnimationEaseInOut == 0, "NSAnimationEaseInOut is 0");
  PASS(NSAnimationEaseIn == 1, "NSAnimationEaseIn is 1");
  PASS(NSAnimationEaseOut == 2, "NSAnimationEaseOut is 2");
  PASS(NSAnimationLinear == 3, "NSAnimationLinear is 3");
  PASS(NSAnimationBlocking == 0, "NSAnimationBlocking is 0");
  PASS(NSAnimationNonblocking == 1, "NSAnimationNonblocking is 1");
  PASS(NSAnimationNonblockingThreaded == 2,
       "NSAnimationNonblockingThreaded is 2");

  a = AUTORELEASE([[NSAnimation alloc]
    initWithDuration: 1.0 animationCurve: NSAnimationEaseInOut]);

  PASS([a duration] == 1.0, "duration is the value passed to init");
  PASS([a animationCurve] == NSAnimationEaseInOut,
       "animationCurve is the value passed to init");
  PASS([a animationBlockingMode] == NSAnimationBlocking,
       "default animationBlockingMode is Blocking");
  PASS([a currentProgress] == 0.0, "default currentProgress is 0");
  PASS([a isAnimating] == NO, "a new animation is not animating");
  PASS([[a progressMarks] count] == 0, "a new animation has no progress marks");
  PASS([a delegate] == nil, "default delegate is nil");

  DESTROY(arp);
  return 0;
}
