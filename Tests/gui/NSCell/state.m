/* Tests the NSCell state machine: setState clamping, the two- and three-state
 * nextState cycles, and the effect of turning mixed state off while a cell is
 * in the mixed state.  These are plain value operations on a cell.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSCell *cell;

  START_SET("NSCell state")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  /* A fresh cell is off and does not allow mixed state. */
  cell = [[NSCell alloc] initTextCell: @"x"];
  pass([cell state] == NSOffState, "a new cell starts in the off state");
  pass([cell allowsMixedState] == NO,
       "a new cell does not allow mixed state");

  /* setState with the canonical constants. */
  [cell setState: NSOnState];
  pass([cell state] == NSOnState, "setState: NSOnState sets the on state");
  [cell setState: NSOffState];
  pass([cell state] == NSOffState, "setState: NSOffState sets the off state");

  /* setState clamps any positive value to the on state. */
  [cell setState: 5];
  pass([cell state] == NSOnState, "setState: with a positive value clamps to on");

  /* Without mixed state allowed, a negative value (and NSMixedState itself)
   * clamps to the on state. */
  [cell setState: -3];
  pass([cell state] == NSOnState,
       "setState: with a negative value clamps to on when mixed is not allowed");
  [cell setState: NSMixedState];
  pass([cell state] == NSOnState,
       "setState: NSMixedState clamps to on when mixed is not allowed");

  /* Once mixed state is allowed, a negative value reaches the mixed state. */
  [cell setAllowsMixedState: YES];
  pass([cell allowsMixedState] == YES, "setAllowsMixedState: YES takes effect");
  [cell setState: NSMixedState];
  pass([cell state] == NSMixedState,
       "setState: NSMixedState sets mixed when mixed is allowed");

  /* nextState without mixed state is a two-state toggle. */
  [cell setAllowsMixedState: NO];
  [cell setState: NSOffState];
  pass([cell nextState] == NSOnState, "the state after off is on");
  [cell setState: NSOnState];
  pass([cell nextState] == NSOffState, "the state after on is off");

  /* nextState with mixed state allowed is a three-state cycle:
   * off -> mixed -> on -> off. */
  [cell setAllowsMixedState: YES];
  [cell setState: NSOffState];
  pass([cell nextState] == NSMixedState, "with mixed allowed, off is followed by mixed");
  [cell setState: NSMixedState];
  pass([cell nextState] == NSOnState, "mixed is followed by on");
  [cell setState: NSOnState];
  pass([cell nextState] == NSOffState, "on is followed by off");

  /* setNextState advances the state along the cycle. */
  [cell setState: NSOffState];
  [cell setNextState];
  pass([cell state] == NSMixedState, "setNextState advances off to mixed");

  /* Turning mixed state off while the cell is mixed moves it out of mixed. */
  [cell setState: NSMixedState];
  [cell setAllowsMixedState: NO];
  pass([cell state] == NSOnState,
       "disallowing mixed state moves a mixed cell to on");

  END_SET("NSCell state")

  DESTROY(arp);
  return 0;
}
