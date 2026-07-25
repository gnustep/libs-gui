/* Coverage for the NSButton convenience constructors: each builds a button
   wired to the given target/action, a push button is bordered while a checkbox
   or radio button is not (and carries a mark image), and the button starts in
   the off state.  Checked against AppKit on a macOS runner.  Building the
   button touches the font/graphics backend, so the set is skipped when the
   backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSGeometry.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSImage.h>

@interface CtorTarget : NSObject
- (void) fire: (id)sender;
@end
@implementation CtorTarget
- (void) fire: (id)sender { }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  CtorTarget *t;
  NSImage *image;

  START_SET("NSButton convenience constructors")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSButton *b;
      SEL a = @selector(fire:);

      t = AUTORELEASE([[CtorTarget alloc] init]);
      image = AUTORELEASE([[NSImage alloc] initWithSize: NSMakeSize(16, 16)]);

      b = [NSButton buttonWithTitle: @"Go" target: t action: a];
      PASS(b != nil && [[b title] isEqual: @"Go"] && [b target] == t
        && sel_isEqual([b action], a) && [b isBordered] == YES
        && [b state] == NSOffState,
        "buttonWithTitle:target:action: makes a bordered push button");

      b = [NSButton buttonWithImage: image target: t action: a];
      PASS(b != nil && [b image] == image && [b target] == t
        && sel_isEqual([b action], a) && [b isBordered] == YES,
        "buttonWithImage:target:action: makes a bordered image button");

      b = [NSButton buttonWithTitle: @"Go" image: image target: t action: a];
      PASS(b != nil && [[b title] isEqual: @"Go"] && [b image] == image
        && [b target] == t && sel_isEqual([b action], a) && [b isBordered] == YES,
        "buttonWithTitle:image:target:action: carries both title and image");

      b = [NSButton checkboxWithTitle: @"Check" target: t action: a];
      PASS(b != nil && [[b title] isEqual: @"Check"] && [b target] == t
        && sel_isEqual([b action], a) && [b isBordered] == NO
        && [b image] != nil && [b state] == NSOffState,
        "checkboxWithTitle:target:action: makes an unbordered checkbox");

      b = [NSButton radioButtonWithTitle: @"Radio" target: t action: a];
      PASS(b != nil && [[b title] isEqual: @"Radio"] && [b target] == t
        && sel_isEqual([b action], a) && [b isBordered] == NO
        && [b image] != nil && [b state] == NSOffState,
        "radioButtonWithTitle:target:action: makes an unbordered radio button");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSButton convenience constructors")

  DESTROY(arp);
  return 0;
}
