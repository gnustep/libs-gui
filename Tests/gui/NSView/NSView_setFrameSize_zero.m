/* Regression test for -[NSView setFrameSize:] on a rotated view whose frame
 * has been collapsed to a zero dimension.
 *
 * A rotated view has _is_rotated_or_scaled_from_base set but keeps
 * _boundsMatrix nil, so -setFrameSize: recomputes the bounds by scaling with
 * (bounds / current frame).  Collapsing the width to zero and then expanding
 * it again divided by that zero width, leaving the bounds width infinite/NaN.
 */
#include "Testing.h"

#include <math.h>
#include <Foundation/Foundation.h>
#include <AppKit/NSView.h>

int
main(int argc, char **argv)
{
  START_SET("NSView setFrameSize zero-dimension rotated")
  ENTER_POOL
  NSView	*view;
  NSSize	bounds;

  view = [[NSView alloc] initWithFrame: NSMakeRect(0.0, 0.0, 100.0, 100.0)];
  [view setFrameRotation: 30.0];
  [view setFrameSize: NSMakeSize(0.0, 100.0)];		/* collapse width */
  [view setFrameSize: NSMakeSize(100.0, 100.0)];	/* expand again */

  bounds = [view bounds].size;
  PASS(isfinite(bounds.width) && isfinite(bounds.height),
    "-setFrameSize: keeps a rotated view's bounds finite across a zero width")
  [view release];

  LEAVE_POOL
  END_SET("NSView setFrameSize zero-dimension rotated")
  return 0;
}
