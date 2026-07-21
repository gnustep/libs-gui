#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSText.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSWindow behaviour")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 120)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);

      /* First responder, field editor and content view. Checked against
         AppKit. */
      PASS([w firstResponder] == w,
        "a new window is its own first responder");

      NSText *fe = [w fieldEditor: YES forObject: nil];
      PASS(fe != nil && [fe isKindOfClass: [NSText class]],
        "fieldEditor:forObject: returns an NSText");

      NSView *cv = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 80, 80)]);
      [w setContentView: cv];
      PASS([w contentView] == cv, "setContentView: sets the content view");
      PASS([cv window] == w, "a content view reports its window");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow behaviour")
  DESTROY(arp);
  return 0;
}
