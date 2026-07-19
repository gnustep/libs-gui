#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSString.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSActionCell.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSControl value")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSControl *c = AUTORELEASE([[NSControl alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 20)]);
      [c setCell: AUTORELEASE([[NSActionCell alloc] initTextCell: @""])];

      /* Value round-trips and cross-type conversions. Checked against AppKit. */
      [c setStringValue: @"hello"];
      PASS([[c stringValue] isEqualToString: @"hello"], "stringValue round-trips");

      [c setIntValue: 42];
      PASS([c intValue] == 42, "intValue round-trips");
      PASS([[c stringValue] isEqualToString: @"42"], "an int value reads back as its decimal string");
      PASS([c doubleValue] == 42.0, "an int value reads back as a double");

      [c setDoubleValue: 3.5];
      PASS([c doubleValue] == 3.5, "doubleValue round-trips");
      PASS([c intValue] == 3, "intValue truncates 3.5 toward zero");
      PASS([[c stringValue] isEqualToString: @"3.5"], "a double value reads back as its string");

      [c setStringValue: @"3.5"];
      PASS([c doubleValue] == 3.5, "a numeric string reads back as a double");
      PASS([c intValue] == 3, "a numeric string reads back as a truncated int");

      [c setStringValue: @"abc"];
      PASS([c intValue] == 0, "a non-numeric string reads back as int 0");
      PASS([c doubleValue] == 0.0, "a non-numeric string reads back as double 0");

      [c setIntegerValue: 99];
      PASS([c integerValue] == 99, "integerValue round-trips");

      [c setFloatValue: 2.5f];
      PASS([c floatValue] == 2.5f, "floatValue round-trips");

      [c setObjectValue: @"obj"];
      PASS([[c objectValue] isEqual: @"obj"], "objectValue round-trips");
      PASS([[c stringValue] isEqualToString: @"obj"], "an object value reads back as its string");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSControl value")
  DESTROY(arp);
  return 0;
}
