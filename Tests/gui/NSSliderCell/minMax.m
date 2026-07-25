#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSSliderCell.h>
#include <AppKit/NSImage.h>

int main()
{
  CREATE_AUTORELEASE_POOL(arp);
  NSSliderCell *cell;

  START_SET("NSSliderCell GNUstep minMax")

  NS_DURING
  {
    [NSApplication sharedApplication];
  }
  NS_HANDLER
  {
    if ([[localException name] isEqualToString: NSInternalInconsistencyException ])
       SKIP("It looks like GNUstep backend is not yet installed")
  }
  NS_ENDHANDLER

  cell = AUTORELEASE([[NSSliderCell alloc] init]);

  PASS([cell isContinuous], "slider continuous by default");

  PASS([cell minValue] == 0.0, "default min value is 0");
  PASS([cell maxValue] == 1.0, "default max value is 1");
  PASS([cell doubleValue] == 0.0, "default value is 0");
  PASS([[cell objectValue] isEqual: [NSNumber numberWithDouble: 0]], "default objectValue is NSNumber 0");

  [cell setMinValue: 2];
  PASS([cell minValue] == 2.0, "set min value to 2");
  PASS([cell maxValue] == 1.0, "max value is still 1");
  PASS([cell doubleValue] == 2.0, "when min < max, value should always be min");
 
  [cell setDoubleValue: -100.0]; 
  PASS([cell doubleValue] == 2.0, "when min < max, value should always be min");
  [cell setDoubleValue: 1];
  PASS([cell doubleValue] == 2.0, "when min < max, value should always be min");
  [cell setDoubleValue: 1.5];
  PASS([cell doubleValue] == 2.0, "when min < max, value should always be min");
  [cell setDoubleValue: 2.0];
  PASS([cell doubleValue] == 2.0, "when min < max, value should always be min");
  [cell setDoubleValue: 2.5];
  PASS([cell doubleValue] == 2.0, "when min < max, value should always be min");
 
  [cell setMaxValue: 10];
  PASS([cell doubleValue] == 2.0, "value is still 2.0");

  [cell setMinValue: 3.0];
  PASS([cell doubleValue] == 3.0, "changing minimum clamps value to 3.0");
  PASS([cell floatValue] == 3.0, "changing minimum clamps value to 3.0");
  
  [cell setDoubleValue: 10];
  [cell setMaxValue: 9];
  PASS([cell doubleValue] == 9.0, "changing max clamps value to 9.0");
  PASS([cell floatValue] == 9.0, "changing max clamps value to 9.0");
 
  // Test value setters

  [cell setObjectValue: @"hello"];
  PASS([cell doubleValue] == 3.0, "setting nonsense string objectValue sets value to min"); 
  [cell setDoubleValue: 9.0];

  [cell setStringValue: @"hello"];
  PASS([cell doubleValue] == 3.0, "setting nonsense string stringValue sets value to min"); 
  [cell setDoubleValue: 9.0];
 
  [cell setObjectValue: nil];
  PASS([cell doubleValue] == 3.0, "setting nil objectValue sets value to min"); 
  [cell setDoubleValue: 9.0];
 
  [cell setObjectValue: @"3.5"];
  PASS([cell doubleValue] == 3.5, "setting @'3.5' objectValue sets value to 3.5"); 
  [cell setDoubleValue: 9.0];
 
  [cell setStringValue: @"3.5"];
  PASS([cell doubleValue] == 3.5, "setting @'3.5' stringValue sets value to 3.5"); 
  [cell setDoubleValue: 9.0];

  [cell setIntValue: 3];
  PASS([cell doubleValue] == 3.0, "setting 3 intValue sets value to 3.0"); 
  [cell setDoubleValue: 9.0];

  // Test setting the value out of bounds with different setters

  [cell setDoubleValue: 3.5];
  [cell setObjectValue: @"-5"];
  PASS([cell doubleValue] == 3.0, "setting @'-5' objectValue sets value to min");
  PASS([cell intValue] == 3, "setting @'-5' objectValue sets value to min (integer)");
  [cell setDoubleValue: 3.5];
  [cell setStringValue: @"-5"];
  PASS([cell doubleValue] == 3.0, "setting @'-5' stringValue sets value to min");
  PASS([cell intValue] == 3, "setting @'-5' objectValue sets value to min (integer)");
  [cell setDoubleValue: 3.5];
  [cell setIntValue: -5];
  PASS([cell doubleValue] == 3.0, "setting -5 intValue sets value to min");
  PASS([cell intValue] == 3, "setting @'-5' objectValue sets value to min (integer)");
  [cell setDoubleValue: 3.5];
  [cell setDoubleValue: -5];
  PASS([cell doubleValue] == 3.0, "setting -5 doubleValue sets value to min");
  PASS([cell intValue] == 3, "setting @'-5' objectValue sets value to min (integer)");
  [cell setDoubleValue: 3.5];
  [cell setFloatValue: -5];
  PASS([cell doubleValue] == 3.0, "setting -5 floatValue sets value to min");
  PASS([cell intValue] == 3, "setting @'-5' objectValue sets value to min (integer)");

  [cell setDoubleValue: 3.5];
  [cell setObjectValue: @"15"];
  PASS([cell doubleValue] == 9.0, "setting @'15' objectValue sets value to max");
  PASS([cell intValue] == 9, "setting @'15' objectValue sets value to max (integer)");
  [cell setDoubleValue: 3.5];
  [cell setStringValue: @"15"];
  PASS([cell doubleValue] == 9.0, "setting @'15' stringValue sets value to max");
  PASS([cell intValue] == 9, "setting @'15' stringValue sets value to max (integer)");
  [cell setDoubleValue: 3.5];
  [cell setIntValue: 15];
  PASS([cell doubleValue] == 9.0, "setting 15 intValue sets value to max");
  PASS([cell intValue] == 9, "setting 15 intValue sets value to max (integer)");
  [cell setDoubleValue: 3.5];
  [cell setDoubleValue: 15];
  PASS([cell doubleValue] == 9.0, "setting 15 doubleValue sets value to max");
  PASS([cell intValue] == 9, "setting 15 doubleValue sets value to max (integer)");
  [cell setDoubleValue: 3.5];
  [cell setFloatValue: 15];
  PASS([cell doubleValue] == 9.0, "setting 15 floatValue sets value to max");
  PASS([cell intValue] == 9, "setting 15 floatValue sets value to max (integer)");

  END_SET("NSSliderCell GNUstep minMax")

  DESTROY(arp);
  return 0;
}

