#import "Testing.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSDrawer.h>

/* -[NSWindow drawers] returns the drawers whose parent window is the receiver.
   The list is empty (but not nil) when there are none, follows
   setParentWindow:, and is per window.  Checked against AppKit.  Creating a
   window and a drawer needs a window server, so the set is guarded. */

static NSWindow *
window(void)
{
  return AUTORELEASE([[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 300, 300)
              styleMask: NSTitledWindowMask
                backing: NSBackingStoreBuffered
                  defer: NO]);
}

static NSDrawer *
drawer(void)
{
  return AUTORELEASE([[NSDrawer alloc]
    initWithContentSize: NSMakeSize(100, 200)
          preferredEdge: NSMinXEdge]);
}

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSWindow *w1, *w2;
  NSDrawer *d1, *d2, *d3;
  NSArray *list;

  START_SET("NSWindow drawers")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      w1 = window();
      w2 = window();
      d1 = drawer();
      d2 = drawer();
      d3 = drawer();

      list = [w1 drawers];
      PASS(list != nil && [list count] == 0,
        "a window with no drawers returns an empty array");

      [d1 setParentWindow: w1];
      list = [w1 drawers];
      PASS([list count] == 1 && [list containsObject: d1],
        "a drawer whose parent window is the receiver is listed");

      [d2 setParentWindow: w1];
      PASS([[w1 drawers] count] == 2,
        "both drawers of the window are listed");

      [d2 setParentWindow: nil];
      list = [w1 drawers];
      PASS([list count] == 1 && [list containsObject: d1]
        && ![list containsObject: d2],
        "clearing a drawer's parent window removes it from the list");

      [d3 setParentWindow: w2];
      PASS(![[w1 drawers] containsObject: d3]
        && [[w2 drawers] containsObject: d3],
        "a drawer is only listed by its own parent window");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSWindow drawers")

  DESTROY(arp);
  return 0;
}
