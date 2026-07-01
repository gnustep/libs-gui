/* Regression tests for the submenu aim-triangle geometry (Tognazzini's wedge)
   used by -[NSMenuView _trackWithEvent:startingMenuView:] when the user default
   GSMenuSubmenuAimTracking is enabled.

   Copyright (C) 2026 Free Software Foundation, Inc.

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
*/

#import "ObjectTesting.h"

#import <Foundation/NSGeometry.h>
#import <AppKit/NSMenuView.h>

/* _mouseAt:aimsAtSubmenuFrame:fromApex:slack: is a private helper; redeclare it
   so the test can exercise the pure geometry without driving a live menu. */
@interface NSMenuView (AimTriangleTesting)
+ (BOOL) _mouseAt: (NSPoint)aPoint aimsAtSubmenuFrame: (NSRect)submenuFrame
         fromApex: (NSPoint)apex slack: (CGFloat)slack;
@end

int main(void)
{
  START_SET("NSMenuView submenu aim triangle")

  /* A submenu that opened to the right of its parent, in y-up screen coords.
     The parent item (and hence the apex) sits to its left, near the top. */
  NSRect  sub  = NSMakeRect(200.0, 100.0, 100.0, 100.0);   /* x:200..300 y:100..200 */
  NSPoint apex = NSMakePoint(190.0, 190.0);

  /* Steering diagonally toward the submenu keeps the pointer inside the wedge. */
  pass([NSMenuView _mouseAt: NSMakePoint(196.0, 150.0)
            aimsAtSubmenuFrame: sub fromApex: apex slack: 4.0],
    "a diagonal move toward the submenu stays inside the wedge");

  /* Deliberately veering above or below the aim line leaves the wedge at once,
     so a sibling item can take over. */
  pass(![NSMenuView _mouseAt: NSMakePoint(192.0, 210.0)
             aimsAtSubmenuFrame: sub fromApex: apex slack: 4.0],
    "a move above the aim line leaves the wedge");
  pass(![NSMenuView _mouseAt: NSMakePoint(192.0, 150.0)
             aimsAtSubmenuFrame: sub fromApex: apex slack: 4.0],
    "a near-vertical move down to a sibling leaves the wedge");

  /* Slack widens the wedge just past the submenu corners: this point is inside
     only because of the 4px slack, and outside with no slack. */
  pass([NSMenuView _mouseAt: NSMakePoint(199.5, 202.0)
            aimsAtSubmenuFrame: sub fromApex: apex slack: 4.0],
    "slack keeps a point just past the top corner inside");
  pass(![NSMenuView _mouseAt: NSMakePoint(199.5, 202.0)
             aimsAtSubmenuFrame: sub fromApex: apex slack: 0.0],
    "without slack the same point falls outside");

  /* A submenu that opened to the left (e.g. nudged by shiftOnScreen): the apex
     is now to its right, and the wedge base must snap to the right edge. */
  pass([NSMenuView _mouseAt: NSMakePoint(304.0, 150.0)
            aimsAtSubmenuFrame: sub fromApex: NSMakePoint(310.0, 150.0) slack: 4.0],
    "a left-opening submenu aims at the right edge");

  END_SET("NSMenuView submenu aim triangle")

  return 0;
}
