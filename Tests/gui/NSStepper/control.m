/* Coverage for the NSStepper control: its cell class, the value defaults it
   exposes through its NSStepperCell, the way it forwards the min/max,
   increment, autorepeat and value-wrapping setters to the cell, and the
   value clamping the cell applies.  The control has a cell that touches the
   font backend, so the set is skipped when the backend is unavailable.
*/
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSStepper.h>
#include <AppKit/NSStepperCell.h>

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSStepper *stepper;

  START_SET("NSStepper control")

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

  pass([NSStepper cellClass] == [NSStepperCell class], "the cell class is NSStepperCell");

  stepper = AUTORELEASE([[NSStepper alloc] initWithFrame: NSMakeRect(0, 0, 20, 30)]);
  pass([[stepper cell] isKindOfClass: [NSStepperCell class]],
       "the stepper is backed by a stepper cell");

  /* Defaults, exposed through the cell. */
  pass([stepper minValue] == 0.0, "default minimum is 0");
  pass([stepper maxValue] == 59.0, "default maximum is 59");
  pass([stepper increment] == 1.0, "default increment is 1");
  pass([stepper valueWraps] == YES, "value wraps by default");
  pass([stepper autorepeat] == YES, "autorepeat is on by default");

  /* The setters are forwarded to the cell. */
  [stepper setMaxValue: 20.0];
  [stepper setMinValue: 5.0];
  [stepper setIncrement: 2.0];
  [stepper setValueWraps: NO];
  [stepper setAutorepeat: NO];
  pass([stepper maxValue] == 20.0 && [stepper minValue] == 5.0
    && [stepper increment] == 2.0 && [stepper valueWraps] == NO
    && [stepper autorepeat] == NO,
    "the control reports the values set on it");
  pass([[stepper cell] maxValue] == 20.0 && [[stepper cell] minValue] == 5.0
    && [[stepper cell] increment] == 2.0 && [[stepper cell] valueWraps] == NO
    && [[stepper cell] autorepeat] == NO,
    "the setters are forwarded to the cell");

  /* The value is clamped to the range by the cell. */
  [stepper setIntValue: 10];
  pass([stepper intValue] == 10, "a value within the range is kept");
  [stepper setIntValue: 100];
  pass([stepper intValue] == 20, "a value above the maximum clamps to the maximum");
  [stepper setIntValue: 0];
  pass([stepper intValue] == 5, "a value below the minimum clamps to the minimum");

  END_SET("NSStepper control")

  DESTROY(arp);
  return 0;
}
