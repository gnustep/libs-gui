/* Coverage for the NSStepperCell value-logic surface: the initial
   defaults, the increment/autorepeat/valueWraps accessors, the clamping
   done by -setMaxValue:/-setMinValue:/-setObjectValue:, and the NSCoding
   round trip.  The tracking-driven -_increment/-_decrement are not
   reachable without a live event stream, so they are not exercised here.
*/
#include "Testing.h"

#include <Foundation/NSArchiver.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSData.h>
#include <Foundation/NSKeyedArchiver.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSStepperCell.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSStepperCell *cell;

  START_SET("NSStepperCell value logic")

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

  /* Defaults set up by -init. */
  cell = AUTORELEASE([[NSStepperCell alloc] init]);
  pass([cell minValue] == 0.0, "default minValue is 0");
  pass([cell maxValue] == 59.0, "default maxValue is 59");
  pass([cell increment] == 1.0, "default increment is 1");
  pass([cell valueWraps] == YES, "value wraps by default");
  pass([cell autorepeat] == YES, "autorepeat is on by default");
  pass([cell doubleValue] == 0.0, "default value is 0");
  pass([cell intValue] == 0, "default intValue is 0");
  pass([[cell objectValue] isEqual: [NSNumber numberWithDouble: 0]],
       "default objectValue is NSNumber 0");

  /* Plain scalar accessors. */
  [cell setIncrement: 2.5];
  pass([cell increment] == 2.5, "setIncrement: stores the increment");
  [cell setValueWraps: NO];
  pass([cell valueWraps] == NO, "setValueWraps: NO clears wrapping");
  [cell setValueWraps: YES];
  pass([cell valueWraps] == YES, "setValueWraps: YES restores wrapping");
  [cell setAutorepeat: NO];
  pass([cell autorepeat] == NO, "setAutorepeat: NO clears autorepeat");
  [cell setAutorepeat: YES];
  pass([cell autorepeat] == YES, "setAutorepeat: YES restores autorepeat");

  /* -setMaxValue: clamps the current value down when it now exceeds max. */
  cell = AUTORELEASE([[NSStepperCell alloc] init]);
  [cell setDoubleValue: 40.0];
  pass([cell doubleValue] == 40.0, "value 40 is accepted within [0,59]");
  [cell setMaxValue: 10.0];
  pass([cell maxValue] == 10.0, "setMaxValue: stores the maximum");
  pass([cell doubleValue] == 10.0, "lowering max below the value clamps it down");
  [cell setMaxValue: 100.0];
  pass([cell doubleValue] == 10.0, "raising max leaves the value untouched");

  /* -setMinValue: clamps the current value up when it now trails min. */
  cell = AUTORELEASE([[NSStepperCell alloc] init]);
  [cell setDoubleValue: 5.0];
  [cell setMinValue: 20.0];
  pass([cell minValue] == 20.0, "setMinValue: stores the minimum");
  pass([cell doubleValue] == 20.0, "raising min above the value clamps it up");
  [cell setMinValue: 0.0];
  pass([cell doubleValue] == 20.0, "lowering min leaves the value untouched");

  /* -setObjectValue: clamps into [min,max]. */
  cell = AUTORELEASE([[NSStepperCell alloc] init]); /* min 0, max 59 */
  [cell setObjectValue: [NSNumber numberWithDouble: 100.0]];
  pass([cell doubleValue] == 59.0, "objectValue above max clamps to max");
  [cell setObjectValue: [NSNumber numberWithDouble: -5.0]];
  pass([cell doubleValue] == 0.0, "objectValue below min clamps to min");
  [cell setObjectValue: [NSNumber numberWithDouble: 30.0]];
  pass([cell doubleValue] == 30.0, "objectValue within range is kept");
  [cell setObjectValue: [NSNumber numberWithDouble: 0.0]];
  pass([cell doubleValue] == 0.0, "objectValue at min is kept");
  [cell setObjectValue: [NSNumber numberWithDouble: 59.0]];
  pass([cell doubleValue] == 59.0, "objectValue at max is kept");

  /* The scalar setters run through the same clamping. */
  [cell setDoubleValue: 100.0];
  pass([cell doubleValue] == 59.0, "doubleValue above max clamps to max");
  [cell setDoubleValue: -5.0];
  pass([cell doubleValue] == 0.0, "doubleValue below min clamps to min");
  [cell setIntValue: 100];
  pass([cell intValue] == 59, "intValue above max clamps to max");
  [cell setIntValue: -5];
  pass([cell intValue] == 0, "intValue below min clamps to min");

  /* A value that does not answer -doubleValue falls back to min. */
  [cell setDoubleValue: 30.0];
  [cell setObjectValue: [NSArray array]];
  pass([cell doubleValue] == 0.0, "objectValue that is not numeric falls back to min");
  [cell setDoubleValue: 30.0];
  [cell setObjectValue: nil];
  pass([cell doubleValue] == 0.0, "nil objectValue falls back to min");

  /* When min > max every objectValue collapses to min. */
  cell = AUTORELEASE([[NSStepperCell alloc] init]);
  [cell setMinValue: 50.0];
  [cell setMaxValue: 10.0];
  pass([cell minValue] == 50.0 && [cell maxValue] == 10.0, "min 50 > max 10 is allowed");
  [cell setObjectValue: [NSNumber numberWithDouble: 30.0]];
  pass([cell doubleValue] == 50.0, "with min > max any objectValue collapses to min");

  /* Keyed archiving round trip. */
  cell = AUTORELEASE([[NSStepperCell alloc] init]);
  [cell setMinValue: -3.0];
  [cell setMaxValue: 7.0];
  [cell setIncrement: 2.0];
  [cell setValueWraps: NO];
  [cell setAutorepeat: NO];
  {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: cell];
    NSStepperCell *copy = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    pass([copy minValue] == -3.0, "keyed archiving preserves minValue");
    pass([copy maxValue] == 7.0, "keyed archiving preserves maxValue");
    pass([copy increment] == 2.0, "keyed archiving preserves increment");
    pass([copy valueWraps] == NO, "keyed archiving preserves valueWraps");
    pass([copy autorepeat] == NO, "keyed archiving preserves autorepeat");
  }

  /* Non-keyed archiving round trip. */
  {
    NSData *data = [NSArchiver archivedDataWithRootObject: cell];
    NSStepperCell *copy = [NSUnarchiver unarchiveObjectWithData: data];
    pass([copy minValue] == -3.0, "non-keyed archiving preserves minValue");
    pass([copy maxValue] == 7.0, "non-keyed archiving preserves maxValue");
    pass([copy increment] == 2.0, "non-keyed archiving preserves increment");
    pass([copy valueWraps] == NO, "non-keyed archiving preserves valueWraps");
    pass([copy autorepeat] == NO, "non-keyed archiving preserves autorepeat");
  }

  END_SET("NSStepperCell value logic")

  DESTROY(arp);
  return 0;
}
