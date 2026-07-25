/* Interaction exercise for NSButton: a click, delivered with -performClick:,
   sends the target/action and advances the button's state the way a real click
   would, and a disabled button swallows the click.  -performClick: drives the
   cell directly, so no window-server event loop is needed, but the set still
   keeps the usual backend skip guard because instantiating the button and its
   cell touches the font/graphics backend. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>

@interface ClickCounter : NSObject
{
@public
  int count;
  id last;
}
- (void) clicked: (id)sender;
@end

@implementation ClickCounter
- (void) clicked: (id)sender
{
  count++;
  last = sender;
}
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  ClickCounter *c;
  NSButton *b;

  START_SET("NSButton interaction")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      c = AUTORELEASE([[ClickCounter alloc] init]);

      /* A momentary button sends its action once per click. */
      b = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 24)]);
      [b setButtonType: NSMomentaryPushInButton];
      [b setTarget: c];
      [b setAction: @selector(clicked:)];
      [b performClick: nil];
      PASS(c->count == 1, "clicking a button sends its action");
      PASS(c->last == b, "the action's sender is the button");

      /* A toggle button advances its state on each click and keeps sending
         the action. */
      c->count = 0;
      b = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 24)]);
      [b setButtonType: NSToggleButton];
      [b setTarget: c];
      [b setAction: @selector(clicked:)];
      PASS([b state] == NSOffState, "a toggle button starts off");
      [b performClick: nil];
      PASS([b state] == NSOnState && c->count == 1,
        "clicking a toggle button turns it on and sends the action");
      [b performClick: nil];
      PASS([b state] == NSOffState && c->count == 2,
        "clicking it again turns it off and sends the action again");

      /* A disabled button ignores the click. */
      c->count = 0;
      b = AUTORELEASE([[NSButton alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 24)]);
      [b setTarget: c];
      [b setAction: @selector(clicked:)];
      [b setEnabled: NO];
      [b performClick: nil];
      PASS(c->count == 0, "a disabled button does not send its action");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSButton interaction")

  DESTROY(arp);
  return 0;
}
