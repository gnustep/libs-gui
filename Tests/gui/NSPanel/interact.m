#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSEvent.h>

/* NSPanel interaction: pressing escape closes a closable panel but leaves a
   panel without a close button alone.  Drives the panel's -keyDown: with a
   synthetic escape event.  Needs a window server, so the set skips cleanly
   without one. */

static NSEvent *
escapeFor(NSWindow *w)
{
  return [NSEvent keyEventWithType: NSKeyDown
                          location: NSZeroPoint
                     modifierFlags: 0
                         timestamp: 0
                      windowNumber: [w windowNumber]
                           context: nil
                        characters: @"\e"
       charactersIgnoringModifiers: @"\e"
                         isARepeat: NO
                           keyCode: 0];
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSPanel interact")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSPanel *closable = AUTORELEASE([[NSPanel alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 150)
                  styleMask: NSTitledWindowMask | NSClosableWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSPanel *fixed = AUTORELEASE([[NSPanel alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 150)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);

      [closable orderFront: nil];
      PASS([closable isVisible] == YES, "the closable panel is shown");
      [closable keyDown: escapeFor(closable)];
      PASS([closable isVisible] == NO,
        "escape closes a closable panel");

      [fixed orderFront: nil];
      PASS([fixed isVisible] == YES, "the non-closable panel is shown");
      [fixed keyDown: escapeFor(fixed)];
      PASS([fixed isVisible] == YES,
        "escape leaves a panel without a close button open");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSPanel interact")
  DESTROY(arp);
  return 0;
}
