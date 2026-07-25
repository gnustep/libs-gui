#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSWindow.h>

/* NSPanel behaviour: making a panel float drives its window level, and a
   utility-style panel floats from the start.  The window level enum values
   differ from Apple's (GNUstep NSFloatingWindowLevel is 2, Apple's is 3), so
   the level is checked against the symbol, not a raw number.  Needs a window
   server, so the set skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSPanel behaviour")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSPanel *p = AUTORELEASE([[NSPanel alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 150)
                  styleMask: NSTitledWindowMask | NSClosableWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);

      [p setFloatingPanel: YES];
      PASS([p isFloatingPanel] == YES, "setFloatingPanel: YES sets the flag");
      PASS([p level] == NSFloatingWindowLevel,
        "a floating panel sits at the floating window level");

      [p setFloatingPanel: NO];
      PASS([p isFloatingPanel] == NO, "setFloatingPanel: NO clears the flag");
      PASS([p level] == NSNormalWindowLevel,
        "clearing floating returns the panel to the normal window level");

      /* a utility-style panel floats from creation */
      NSPanel *u = AUTORELEASE([[NSPanel alloc]
        initWithContentRect: NSMakeRect(0, 0, 100, 80)
                  styleMask: NSTitledWindowMask | NSUtilityWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      PASS([u isFloatingPanel] == YES, "a utility panel is floating");
      PASS([u level] == NSFloatingWindowLevel,
        "a utility panel sits at the floating window level");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSPanel behaviour")
  DESTROY(arp);
  return 0;
}
