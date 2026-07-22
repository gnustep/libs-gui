#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSResponder.h>
#import <AppKit/NSEvent.h>

@interface Recorder : NSResponder
{
@public
  BOOL gotAction;
  BOOL gotKey;
}
@end
@implementation Recorder
- (void) doRecordedAction: (id)o { gotAction = YES; }
- (void) keyDown: (NSEvent *)e { gotKey = YES; }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSResponder chain")

  NSResponder *r = AUTORELEASE([NSResponder new]);
  PASS([r nextResponder] == nil, "nextResponder defaults to nil");

  NSResponder *x = AUTORELEASE([NSResponder new]);
  NSResponder *y = AUTORELEASE([NSResponder new]);
  [x setNextResponder: y];
  PASS([x nextResponder] == y, "setNextResponder: round-trips");

  /* tryToPerform:with: forwards an action the receiver does not handle to its
     nextResponder, and returns YES when it is handled there. Checked against
     AppKit. */
  Recorder *b = AUTORELEASE([Recorder new]);
  NSResponder *a = AUTORELEASE([NSResponder new]);
  [a setNextResponder: b];
  BOOL fwd = [a tryToPerform: @selector(doRecordedAction:) with: nil];
  PASS(fwd == YES, "tryToPerform:with: returns YES when the chain handles it");
  PASS(b->gotAction == YES,
    "tryToPerform:with: forwards the action to nextResponder");

  NSResponder *c = AUTORELEASE([NSResponder new]);
  PASS([c tryToPerform: @selector(doRecordedAction:) with: nil] == NO,
    "tryToPerform:with: returns NO when nobody handles it");

  /* A default event method forwards the event up the chain. */
  Recorder *eb = AUTORELEASE([Recorder new]);
  NSResponder *ea = AUTORELEASE([NSResponder new]);
  [ea setNextResponder: eb];
  NSEvent *ke = [NSEvent keyEventWithType: NSKeyDown
                                 location: NSZeroPoint
                            modifierFlags: 0
                                timestamp: 0.0
                             windowNumber: 0
                                  context: nil
                               characters: @"a"
              charactersIgnoringModifiers: @"a"
                                isARepeat: NO
                                  keyCode: 0];
  [ea keyDown: ke];
  PASS(eb->gotKey == YES,
    "default keyDown: forwards the event to nextResponder");

  END_SET("NSResponder chain")
  DESTROY(arp);
  return 0;
}
