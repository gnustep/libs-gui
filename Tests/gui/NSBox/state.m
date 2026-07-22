#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSBox.h>
#import <AppKit/NSColor.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSBox state")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSBox *box = AUTORELEASE([[NSBox alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);

      /* State round-trips. Checked against AppKit. */
      [box setTitle: @"Hi"];
      PASS([[box title] isEqualToString: @"Hi"], "setTitle: round-trips");
      [box setTitlePosition: NSAtTop];
      PASS([box titlePosition] == NSAtTop, "setTitlePosition: round-trips");
      [box setBoxType: NSBoxCustom];
      PASS([box boxType] == NSBoxCustom, "setBoxType: round-trips");
      [box setBorderType: NSLineBorder];
      PASS([box borderType] == NSLineBorder, "setBorderType: round-trips");
      [box setContentViewMargins: NSMakeSize(8, 6)];
      PASS(NSEqualSizes([box contentViewMargins], NSMakeSize(8, 6)),
        "setContentViewMargins: round-trips");
      [box setFillColor: [NSColor redColor]];
      PASS([[box fillColor] isEqual: [NSColor redColor]], "setFillColor: round-trips");
      [box setBorderColor: [NSColor blueColor]];
      PASS([[box borderColor] isEqual: [NSColor blueColor]], "setBorderColor: round-trips");
      [box setBorderWidth: 3.0];
      PASS([box borderWidth] == 3.0, "setBorderWidth: round-trips");
      [box setCornerRadius: 5.0];
      PASS([box cornerRadius] == 5.0, "setCornerRadius: round-trips");
      [box setTransparent: YES];
      PASS([box isTransparent] == YES, "setTransparent: round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSBox state")
  DESTROY(arp);
  return 0;
}
