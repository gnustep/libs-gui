#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSResponder.h>
#import <AppKit/NSEvent.h>

@interface GestureRecorder : NSResponder
{
@public
  SEL last;
}
@end

@implementation GestureRecorder
- (void) cursorUpdate: (NSEvent *)e { last = _cmd; }
- (void) magnifyWithEvent: (NSEvent *)e { last = _cmd; }
- (void) rotateWithEvent: (NSEvent *)e { last = _cmd; }
- (void) swipeWithEvent: (NSEvent *)e { last = _cmd; }
- (void) touchesBeganWithEvent: (NSEvent *)e { last = _cmd; }
- (void) touchesMovedWithEvent: (NSEvent *)e { last = _cmd; }
- (void) touchesEndedWithEvent: (NSEvent *)e { last = _cmd; }
- (void) touchesCancelledWithEvent: (NSEvent *)e { last = _cmd; }
- (void) smartMagnifyWithEvent: (NSEvent *)e { last = _cmd; }
- (void) pressureChangeWithEvent: (NSEvent *)e { last = _cmd; }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSResponder gesture events")

  /* NSResponder implements the gesture, touch, cursor-update and pressure
     event methods; the default implementation forwards the event to the
     next responder, matching AppKit. */
  GestureRecorder *b = AUTORELEASE([GestureRecorder new]);
  NSResponder *a = AUTORELEASE([NSResponder new]);
  [a setNextResponder: b];

  b->last = 0;
  [a cursorUpdate: nil];
  PASS(sel_isEqual(b->last, @selector(cursorUpdate:)),
    "default cursorUpdate: forwards to nextResponder");

  b->last = 0;
  [a magnifyWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(magnifyWithEvent:)),
    "default magnifyWithEvent: forwards to nextResponder");

  b->last = 0;
  [a rotateWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(rotateWithEvent:)),
    "default rotateWithEvent: forwards to nextResponder");

  b->last = 0;
  [a swipeWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(swipeWithEvent:)),
    "default swipeWithEvent: forwards to nextResponder");

  b->last = 0;
  [a touchesBeganWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(touchesBeganWithEvent:)),
    "default touchesBeganWithEvent: forwards to nextResponder");

  b->last = 0;
  [a touchesMovedWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(touchesMovedWithEvent:)),
    "default touchesMovedWithEvent: forwards to nextResponder");

  b->last = 0;
  [a touchesEndedWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(touchesEndedWithEvent:)),
    "default touchesEndedWithEvent: forwards to nextResponder");

  b->last = 0;
  [a touchesCancelledWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(touchesCancelledWithEvent:)),
    "default touchesCancelledWithEvent: forwards to nextResponder");

  b->last = 0;
  [a smartMagnifyWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(smartMagnifyWithEvent:)),
    "default smartMagnifyWithEvent: forwards to nextResponder");

  b->last = 0;
  [a pressureChangeWithEvent: nil];
  PASS(sel_isEqual(b->last, @selector(pressureChangeWithEvent:)),
    "default pressureChangeWithEvent: forwards to nextResponder");

  END_SET("NSResponder gesture events")
  DESTROY(arp);
  return 0;
}
