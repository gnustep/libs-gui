/* NSAnimation progress marks.  Added marks are reported in sorted order and a
   removed mark drops out; -progressMarks can be called repeatedly as the marks
   change (it caches the numbers it returns, which the animation must own); and
   setProgressMarks: replaces the set or clears it when passed nil. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSValue.h>

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
  PASS([marks count] == 3
    && [[marks objectAtIndex: 0] floatValue] == 0.25
    && [[marks objectAtIndex: 1] floatValue] == 0.5
    && [[marks objectAtIndex: 2] floatValue] == 0.75,
       "added marks are reported in sorted order");

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

  a = AUTORELEASE([[NSAnimation alloc]
    initWithDuration: 1.0 animationCurve: NSAnimationLinear]);
  [a addProgressMark: 0.1];
  [a setProgressMarks: [NSArray arrayWithObjects:
    [NSNumber numberWithFloat: 0.75],
    [NSNumber numberWithFloat: 0.25], nil]];
  marks = [a progressMarks];
  PASS([marks count] == 2
    && [[marks objectAtIndex: 0] floatValue] == 0.25
    && [[marks objectAtIndex: 1] floatValue] == 0.75,
       "setProgressMarks: replaces the previous marks, sorted");

  DESTROY(arp);
  return 0;
}
