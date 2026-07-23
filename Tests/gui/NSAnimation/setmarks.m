/* NSAnimation -setProgressMarks: replaces the current marks with the ones in
   the array, reported in sorted order, and clears them when passed nil. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSAnimation.h>

static NSAnimation *
freshAnimation(void)
{
  return AUTORELEASE([[NSAnimation alloc]
    initWithDuration: 1.0 animationCurve: NSAnimationLinear]);
}

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSAnimation *a;
  NSArray *marks;

  a = freshAnimation();
  [a addProgressMark: 0.1];
  [a setProgressMarks: [NSArray arrayWithObjects:
    [NSNumber numberWithFloat: 0.75],
    [NSNumber numberWithFloat: 0.25], nil]];
  marks = [a progressMarks];
  PASS([marks count] == 2, "setProgressMarks: replaces the previous marks");
  PASS([[marks objectAtIndex: 0] floatValue] == 0.25
    && [[marks objectAtIndex: 1] floatValue] == 0.75,
       "the new marks are reported in sorted order");

  a = freshAnimation();
  [a addProgressMark: 0.5];
  [a setProgressMarks: nil];
  PASS([[a progressMarks] count] == 0, "setProgressMarks: nil clears the marks");

  a = freshAnimation();
  [a setProgressMarks: [NSArray arrayWithObject:
    [NSNumber numberWithFloat: 0.25]]];
  [a addProgressMark: 0.75];
  PASS([[a progressMarks] count] == 2,
       "a mark can be added after the set is replaced");

  DESTROY(arp);
  return 0;
}
