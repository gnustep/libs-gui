/* Coverage for NSAnimation setters: the duration, frame rate, animation curve,
   blocking mode, current progress and delegate all round-trip, and the current
   progress is clamped to the unit interval.  Matches AppKit (verified on a
   macOS runner) and passes on unmodified GNUstep. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSObject.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAnimation.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSAnimation *a;
  NSObject *delegate;

  a = AUTORELEASE([[NSAnimation alloc]
    initWithDuration: 1.0 animationCurve: NSAnimationEaseInOut]);

  [a setDuration: 2.5];
  PASS([a duration] == 2.5, "duration round-trips");
  [a setFrameRate: 30.0];
  PASS([a frameRate] == 30.0, "frameRate round-trips");

  [a setAnimationCurve: NSAnimationEaseIn];
  PASS([a animationCurve] == NSAnimationEaseIn, "animationCurve set to EaseIn");
  [a setAnimationCurve: NSAnimationEaseOut];
  PASS([a animationCurve] == NSAnimationEaseOut, "animationCurve set to EaseOut");
  [a setAnimationCurve: NSAnimationLinear];
  PASS([a animationCurve] == NSAnimationLinear, "animationCurve set to Linear");

  [a setAnimationBlockingMode: NSAnimationNonblocking];
  PASS([a animationBlockingMode] == NSAnimationNonblocking,
       "animationBlockingMode set to Nonblocking");
  [a setAnimationBlockingMode: NSAnimationNonblockingThreaded];
  PASS([a animationBlockingMode] == NSAnimationNonblockingThreaded,
       "animationBlockingMode set to NonblockingThreaded");

  [a setCurrentProgress: 0.5];
  PASS([a currentProgress] == 0.5, "currentProgress round-trips");
  [a setCurrentProgress: 1.5];
  PASS([a currentProgress] == 1.0, "currentProgress is clamped to 1");
  [a setCurrentProgress: -0.5];
  PASS([a currentProgress] == 0.0, "currentProgress is clamped to 0");

  delegate = AUTORELEASE([[NSObject alloc] init]);
  [a setDelegate: delegate];
  PASS([a delegate] == delegate, "delegate round-trips");

  DESTROY(arp);
  return 0;
}
