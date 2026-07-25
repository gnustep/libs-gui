#import "Testing.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSDrawer.h>

/* NSDrawer state: its edge, sizes, offsets, content view and parent window,
   and their round-trips.  Creating a drawer builds a drawer window, so the set
   skips cleanly without a window server. */

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSDrawer config")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSDrawer *d = AUTORELEASE([[NSDrawer alloc]
        initWithContentSize: NSMakeSize(100, 100)
              preferredEdge: NSMinXEdge]);

      /* defaults */
      PASS([d state] == NSDrawerClosedState, "a new drawer is closed");
      PASS([d preferredEdge] == NSMinXEdge,
        "the preferred edge is the one it was created with");
      PASS(NSEqualSizes([d contentSize], NSMakeSize(100, 100)),
        "the content size is the one it was created with");
      PASS([d leadingOffset] == 0.0,
        "the leading offset is zero on a side edge");
      PASS([d parentWindow] == nil, "a new drawer has no parent window");
      PASS([d contentView] != nil, "a new drawer has a content view");

      /* size and offset round-trips */
      [d setMinContentSize: NSMakeSize(50, 50)];
      PASS(NSEqualSizes([d minContentSize], NSMakeSize(50, 50)),
        "the minimum content size round-trips");
      [d setMaxContentSize: NSMakeSize(400, 300)];
      PASS(NSEqualSizes([d maxContentSize], NSMakeSize(400, 300)),
        "the maximum content size round-trips");
      [d setLeadingOffset: 12.0];
      PASS([d leadingOffset] == 12.0, "the leading offset round-trips");
      [d setTrailingOffset: 8.0];
      PASS([d trailingOffset] == 8.0, "the trailing offset round-trips");
      [d setPreferredEdge: NSMaxYEdge];
      PASS([d preferredEdge] == NSMaxYEdge, "the preferred edge round-trips");

      /* content view and parent window round-trips */
      {
        NSView *cv = AUTORELEASE([[NSView alloc]
          initWithFrame: NSMakeRect(0, 0, 100, 100)]);
        NSWindow *w = AUTORELEASE([[NSWindow alloc]
          initWithContentRect: NSMakeRect(0, 0, 300, 200)
                    styleMask: NSTitledWindowMask
                      backing: NSBackingStoreBuffered
                        defer: NO]);
        [d setContentView: cv];
        PASS([d contentView] == cv, "the content view round-trips");
        [d setParentWindow: w];
        PASS([d parentWindow] == w, "the parent window round-trips");
      }
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSDrawer config")
  DESTROY(arp);
  return 0;
}
