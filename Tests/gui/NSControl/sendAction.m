#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSActionCell.h>

@interface Recorder : NSObject
{
@public
  BOOL got;
}
@end
@implementation Recorder
- (void) recorded: (id)sender { got = YES; }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSControl sendAction")

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

      Recorder *r = AUTORELEASE([Recorder new]);
      [c setTarget: r];
      [c setAction: @selector(recorded:)];

      /* sendAction:to: dispatches the action to the target. Checked against
         AppKit. */
      BOOL sent = [c sendAction: [c action] to: [c target]];
      PASS(sent == YES,
        "sendAction:to: reports success when the target handles the action");
      PASS(r->got == YES,
        "sendAction:to: invokes the action method on the target");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSControl sendAction")
  DESTROY(arp);
  return 0;
}
