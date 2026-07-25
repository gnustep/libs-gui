/* Tests the coupling between an NSButtonCell's value and its state.  A button
 * cell has no separate value: its int/object/string value is derived from the
 * cell state, and setting any of them sets the state.  These are plain value
 * operations on a cell.
 */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSButtonCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSButtonCell *cell;

  START_SET("NSButtonCell state and value coupling")

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

  cell = AUTORELEASE([[NSButtonCell alloc] init]);

  /* setIntValue reduces the value to a state: any non-zero is on, zero is off,
   * and intValue reads the state back (so 5 becomes 1). */
  [cell setIntValue: 1];
  PASS([cell state] == NSOnState && [cell intValue] == 1,
       "setIntValue: 1 sets the on state and reads back 1");
  [cell setIntValue: 0];
  PASS([cell state] == NSOffState && [cell intValue] == 0,
       "setIntValue: 0 sets the off state and reads back 0");
  [cell setIntValue: 5];
  PASS([cell state] == NSOnState && [cell intValue] == 1,
       "setIntValue: 5 is reduced to the on state and reads back 1");

  /* The state drives the object value. */
  [cell setState: NSOnState];
  PASS([[cell objectValue] intValue] == 1,
       "the object value of an on cell is 1");
  [cell setState: NSOffState];
  PASS([[cell objectValue] boolValue] == NO,
       "the object value of an off cell is false");

  /* Float and double value also read the state. */
  [cell setState: NSOnState];
  PASS([cell floatValue] == 1.0 && [cell doubleValue] == 1.0,
       "the float and double value of an on cell are 1");

  /* Mixed state is carried through the value as -1. */
  [cell setAllowsMixedState: YES];
  [cell setState: NSMixedState];
  PASS([cell intValue] == -1 && [[cell objectValue] intValue] == -1,
       "the value of a mixed cell is -1");

  /* setObjectValue maps through the object: nil is off, a number sets the
   * state from its intValue, mixed comes from -1. */
  [cell setObjectValue: nil];
  PASS([cell state] == NSOffState, "a nil object value sets the off state");
  [cell setObjectValue: [NSNumber numberWithInt: 1]];
  PASS([cell state] == NSOnState, "an object value of 1 sets the on state");
  [cell setObjectValue: [NSNumber numberWithInt: 0]];
  PASS([cell state] == NSOffState, "an object value of 0 sets the off state");
  [cell setObjectValue: [NSNumber numberWithInt: -1]];
  PASS([cell state] == NSMixedState,
       "an object value of -1 sets the mixed state when mixed is allowed");

  /* The string value follows the state, and setting it sets the state from
   * whether the string is empty. */
  [cell setState: NSOnState];
  PASS([[cell stringValue] isEqualToString: @"1"],
       "the string value of an on cell is 1");
  [cell setStringValue: @"x"];
  PASS([cell state] == NSOnState, "a non-empty string value sets the on state");
  [cell setStringValue: @""];
  PASS([cell state] == NSOffState, "an empty string value sets the off state");

  END_SET("NSButtonCell state and value coupling")

  DESTROY(arp);
  return 0;
}
