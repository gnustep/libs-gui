/* Interaction exercise for the NSControl base class: a click delivered with
   -performClick: runs through the control's cell and sends the target/action
   the way a real click would, a disabled control swallows the click, and
   -sendAction:to: refuses a nil action.  -performClick: drives the cell
   directly, so no window-server event loop is needed, but the set keeps the
   usual backend skip guard because instantiating the control and its cell
   touches the font/graphics backend. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSActionCell.h>

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

static NSControl *
makeControl(void)
{
  NSControl *c = AUTORELEASE([[NSControl alloc]
    initWithFrame: NSMakeRect(0, 0, 100, 20)]);
  [c setCell: AUTORELEASE([[NSActionCell alloc] initTextCell: @""])];
  return c;
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  ClickCounter *r;
  NSControl *c;

  START_SET("NSControl interaction")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      r = AUTORELEASE([[ClickCounter alloc] init]);

      /* A click sends the control's action to its target. */
      c = makeControl();
      [c setTarget: r];
      [c setAction: @selector(clicked:)];
      [c performClick: nil];
      PASS(r->count == 1, "clicking a control sends its action");
      PASS(r->last == c, "the action's sender is the control");

      /* The base control has no toggle state, so each click sends again. */
      [c performClick: nil];
      PASS(r->count == 2, "clicking again sends the action again");

      /* A disabled control ignores the click. */
      r->count = 0;
      c = makeControl();
      [c setTarget: r];
      [c setAction: @selector(clicked:)];
      [c setEnabled: NO];
      [c performClick: nil];
      PASS(r->count == 0, "a disabled control does not send its action");

      /* Re-enabling lets the click through again. */
      [c setEnabled: YES];
      [c performClick: nil];
      PASS(r->count == 1, "re-enabling the control restores the click");

      /* -sendAction:to: refuses a nil action and calls nothing. */
      r->count = 0;
      c = makeControl();
      PASS([c sendAction: (SEL)0 to: r] == NO,
        "sendAction:to: returns NO for a nil action");
      PASS(r->count == 0, "a nil action invokes nothing");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSControl interaction")

  DESTROY(arp);
  return 0;
}
