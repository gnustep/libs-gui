#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSActionCell.h>
#import <AppKit/NSText.h>

@interface CtlTarget : NSObject
@end
@implementation CtlTarget
- (void) act: (id)sender {}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSControl state")

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

      /* Target, action and state round-trip. Checked against AppKit. */
      CtlTarget *t = AUTORELEASE([CtlTarget new]);
      [c setTarget: t];
      PASS([c target] == t, "setTarget: round-trips");

      [c setAction: @selector(act:)];
      PASS([c action] == @selector(act:), "setAction: round-trips");

      [c setEnabled: NO];
      PASS([c isEnabled] == NO, "setEnabled:NO round-trips");
      [c setEnabled: YES];
      PASS([c isEnabled] == YES, "setEnabled:YES round-trips");

      [c setTag: 7];
      PASS([c tag] == 7, "setTag: round-trips");

      [c setAlignment: NSTextAlignmentRight];
      PASS([c alignment] == NSTextAlignmentRight, "setAlignment: round-trips");

      [c setContinuous: YES];
      PASS([c isContinuous] == YES, "setContinuous: round-trips");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSControl state")
  DESTROY(arp);
  return 0;
}
