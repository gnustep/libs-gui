#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSBox.h>
#import <AppKit/NSView.h>

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSBox content view")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSBox *box = AUTORELEASE([[NSBox alloc]
        initWithFrame: NSMakeRect(0, 0, 100, 100)]);

      /* Content view wiring. Checked against AppKit. */
      PASS([box contentView] != nil, "a box has a content view by default");

      NSView *cv = AUTORELEASE([[NSView alloc]
        initWithFrame: NSMakeRect(0, 0, 20, 20)]);
      [box setContentView: cv];
      PASS([box contentView] == cv, "setContentView: round-trips");
      PASS([cv superview] == box, "the content view's superview is the box");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSBox content view")
  DESTROY(arp);
  return 0;
}
