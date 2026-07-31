/* NSColorPanel posts NSColorPanelColorDidChangeNotification when its color is
   set, sends its target action, and reflects the new color.  config.m covers
   the panel defaults; this covers the color change.  The shared color panel
   builds its pickers with the theme and font backend, so the set is skipped
   when the backend is unavailable. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSColorPanel.h>

@interface Recorder : NSObject
{
@public
  int changeCount;
  int actionCount;
}
- (void) changed: (NSNotification *)n;
- (void) colorAction: (id)sender;
@end

@implementation Recorder
- (void) changed: (NSNotification *)n
{
  changeCount++;
}
- (void) colorAction: (id)sender
{
  actionCount++;
}
@end

int
main(int argc, char **argv)
{
  Recorder *r;
  NSColorPanel *cp;
  NSNotificationCenter *nc;

  START_SET("NSColorPanel color notification")

  NS_DURING
    {
      [NSApplication sharedApplication];
      cp = [NSColorPanel sharedColorPanel];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("It looks like GNUstep backend is not yet installed")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  NS_DURING
    {
      r = AUTORELEASE([[Recorder alloc] init]);
      nc = [NSNotificationCenter defaultCenter];

      [nc addObserver: r
             selector: @selector(changed:)
                 name: NSColorPanelColorDidChangeNotification
               object: cp];

      /* Setting the color posts the change notification and updates the color. */
      [cp setColor: [NSColor redColor]];
      PASS(r->changeCount == 1, "setColor: posts the color change notification");
      PASS([[[cp color] colorSpaceName] length] > 0 && [cp color] != nil,
        "the panel reports a color after setColor:");

      /* With a target and action set, changing the color sends the action. */
      [cp setTarget: r];
      [cp setAction: @selector(colorAction:)];
      [cp setColor: [NSColor blueColor]];
      PASS(r->changeCount == 2, "a further setColor: posts again");
      PASS(r->actionCount == 1, "setColor: sends the panel target action");

      [nc removeObserver: r];
      [cp setTarget: nil];
      [cp setAction: (SEL)0];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      else
        [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSColorPanel color notification")

  return 0;
}
