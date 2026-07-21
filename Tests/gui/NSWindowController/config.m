#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSWindowController.h>

/* State and round-trips for NSWindowController.  Creating a window needs a
   backend, so this keeps the usual guard. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSWindowController config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 200, 120)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSWindowController *wc = AUTORELEASE([[NSWindowController alloc]
        initWithWindow: w]);

      PASS([wc window] == w, "initWithWindow: sets the window");
      PASS([wc isWindowLoaded] == YES,
        "a controller created with a window is already loaded");
      PASS([wc owner] == wc, "the default owner is the controller itself");

      /* shouldCascadeWindows defaults to YES; checked against AppKit. */
      PASS([wc shouldCascadeWindows] == YES,
        "shouldCascadeWindows defaults to YES");
      [wc setShouldCascadeWindows: NO];
      PASS([wc shouldCascadeWindows] == NO,
        "setShouldCascadeWindows: round-trips");

      [wc setWindowFrameAutosaveName: @"frame"];
      PASS([[wc windowFrameAutosaveName] isEqual: @"frame"],
        "windowFrameAutosaveName round-trips");
      PASS([[w frameAutosaveName] isEqual: @"frame"],
        "the name is forwarded to the window");

      [wc setDocumentEdited: YES];
      /* setDocumentEdited: forwards to the window's documentEdited flag. */
      PASS([w isDocumentEdited] == YES,
        "setDocumentEdited: marks the window edited");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindowController config")
  DESTROY(arp);
  return 0;
}
