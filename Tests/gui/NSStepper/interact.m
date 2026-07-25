/* Interaction exercise for NSStepper: clicking the upper arrow increments the
   value and the lower arrow decrements it, and each click sends the action.
   The clicks are delivered as real events through GSClick, so this needs a
   window server and keeps the usual START_SET / SKIP guard. */
#import "Testing.h"
#import "../GSRenderTest.h"

#import <AppKit/NSApplication.h>
#import <AppKit/NSStepper.h>
#import <AppKit/NSWindow.h>

@interface StepTarget : NSObject
{
@public
  int count;
}
- (void) stepped: (id)sender;
@end

@implementation StepTarget
- (void) stepped: (id)sender
{
  count++;
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  StepTarget *t;
  NSStepper *st;
  NSWindow *w;

  START_SET("NSStepper interaction")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      t = AUTORELEASE([[StepTarget alloc] init]);
      st = AUTORELEASE([[NSStepper alloc]
        initWithFrame: NSMakeRect(10, 10, 20, 40)]);
      [st setMinValue: 0.0];
      [st setMaxValue: 10.0];
      [st setIncrement: 1.0];
      [st setValueWraps: NO];
      [st setDoubleValue: 5.0];
      [st setTarget: t];
      [st setAction: @selector(stepped:)];

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 60, 60)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [[w contentView] addSubview: st];

      /* The upper arrow (top half of the stepper) increments. */
      GSClick(w, st, NSMakePoint(10, 30));
      PASS([st doubleValue] == 6.0 && t->count == 1,
        "clicking the upper arrow increments the value and sends the action");

      /* The lower arrow (bottom half) decrements. */
      GSClick(w, st, NSMakePoint(10, 10));
      PASS([st doubleValue] == 5.0 && t->count == 2,
        "clicking the lower arrow decrements the value and sends the action");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSStepper interaction")

  DESTROY(arp);
  return 0;
}
