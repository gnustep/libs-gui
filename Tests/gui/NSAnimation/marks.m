/* Coverage for NSAnimation progress marks: added marks are reported in sorted
   order and a removed mark drops out.  Matches AppKit (verified on a macOS
   runner) and passes on unmodified GNUstep. */
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
  PASS([marks count] == 3, "three added marks are reported");
  PASS([[marks objectAtIndex: 0] floatValue] == 0.25,
       "marks are reported in sorted order (first)");
  PASS([[marks objectAtIndex: 1] floatValue] == 0.5,
       "marks are reported in sorted order (middle)");
  PASS([[marks objectAtIndex: 2] floatValue] == 0.75,
       "marks are reported in sorted order (last)");

  a = AUTORELEASE([[NSAnimation alloc]
    initWithDuration: 1.0 animationCurve: NSAnimationLinear]);
  [a addProgressMark: 0.5];
  [a addProgressMark: 0.25];
  [a addProgressMark: 0.75];
  [a removeProgressMark: 0.5];
  marks = [a progressMarks];
  PASS([marks count] == 2, "a removed mark drops out");
  PASS([[marks objectAtIndex: 0] floatValue] == 0.25
    && [[marks objectAtIndex: 1] floatValue] == 0.75,
       "the remaining marks are the ones not removed");

  DESTROY(arp);
  return 0;
}
