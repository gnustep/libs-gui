/* Coverage for NSAnimation -currentValue.  On the linear curve the value equals
   the progress; every curve starts at 0 and ends at 1, and the ease-in-out
   curve is symmetric at the midpoint.  Each value is sampled on a fresh
   animation, since changing the curve of an animation that already has progress
   blends the two curves.  Matches AppKit (verified on a macOS runner) and
   passes on unmodified GNUstep. */
#include "Testing.h"

#include <math.h>

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAnimation.h>

#define NEAR(a, b) (fabs((double)(a) - (double)(b)) < 1e-5)

static float
valueFor(NSAnimationCurve curve, float progress)
{
  NSAnimation *a = [[NSAnimation alloc]
    initWithDuration: 1.0 animationCurve: curve];
  float value;

  [a setCurrentProgress: progress];
  value = [a currentValue];
  RELEASE(a);
  return value;
}

int main()
{
  CREATE_AUTORELEASE_POOL(arp);

  PASS(NEAR(valueFor(NSAnimationLinear, 0.25), 0.25),
       "linear value at 0.25 is 0.25");
  PASS(NEAR(valueFor(NSAnimationLinear, 0.5), 0.5),
       "linear value at 0.5 is 0.5");
  PASS(NEAR(valueFor(NSAnimationLinear, 0.75), 0.75),
       "linear value at 0.75 is 0.75");

  PASS(NEAR(valueFor(NSAnimationEaseInOut, 0.0), 0.0),
       "ease-in-out value at 0 is 0");
  PASS(NEAR(valueFor(NSAnimationEaseInOut, 0.5), 0.5),
       "ease-in-out value at 0.5 is 0.5");
  PASS(NEAR(valueFor(NSAnimationEaseInOut, 1.0), 1.0),
       "ease-in-out value at 1 is 1");

  PASS(NEAR(valueFor(NSAnimationEaseIn, 0.0), 0.0), "ease-in value at 0 is 0");
  PASS(NEAR(valueFor(NSAnimationEaseIn, 1.0), 1.0), "ease-in value at 1 is 1");
  PASS(NEAR(valueFor(NSAnimationEaseOut, 1.0), 1.0), "ease-out value at 1 is 1");

  DESTROY(arp);
  return 0;
}
