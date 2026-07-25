#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSWindow.h>

/* NSPanel state: the panel behaviour flags and the window defaults a panel
   sets for itself, plus their round-trips.  Creating a panel needs a window
   server, so the set skips cleanly without one. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSPanel config")

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

      /* behaviour-flag defaults */
      PASS([p worksWhenModal] == NO,
        "a panel does not work when modal by default");
      PASS([p becomesKeyOnlyIfNeeded] == NO,
        "a panel does not become key only if needed by default");
      PASS([p isFloatingPanel] == NO,
        "a panel is not floating by default");

      /* window defaults a panel sets for itself */
      PASS([p hidesOnDeactivate] == YES,
        "a panel hides on deactivate by default");
      PASS([p isReleasedWhenClosed] == NO,
        "a panel is not released when closed by default");
      PASS([p level] == NSNormalWindowLevel,
        "a panel sits at the normal window level by default");

      /* a panel can become key but not main */
      PASS([p canBecomeKeyWindow] == YES, "a panel can become key");
      PASS([p canBecomeMainWindow] == NO, "a panel cannot become main");

      /* flag round-trips */
      [p setWorksWhenModal: YES];
      PASS([p worksWhenModal] == YES, "worksWhenModal round-trips to YES");
      [p setWorksWhenModal: NO];
      PASS([p worksWhenModal] == NO, "worksWhenModal round-trips to NO");

      [p setBecomesKeyOnlyIfNeeded: YES];
      PASS([p becomesKeyOnlyIfNeeded] == YES,
        "becomesKeyOnlyIfNeeded round-trips to YES");
      [p setBecomesKeyOnlyIfNeeded: NO];
      PASS([p becomesKeyOnlyIfNeeded] == NO,
        "becomesKeyOnlyIfNeeded round-trips to NO");

      [p setExcludedFromWindowsMenu: NO];
      PASS([p isExcludedFromWindowsMenu] == NO,
        "excludedFromWindowsMenu round-trips to NO");
      [p setExcludedFromWindowsMenu: YES];
      PASS([p isExcludedFromWindowsMenu] == YES,
        "excludedFromWindowsMenu round-trips to YES");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSPanel config")
  DESTROY(arp);
  return 0;
}
