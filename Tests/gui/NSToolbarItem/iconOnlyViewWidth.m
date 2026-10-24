#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSToolbar.h>
#include <AppKit/NSToolbarItem.h>
#include <AppKit/NSWindow.h>

@interface IOWDelegate : NSObject
@end

@implementation IOWDelegate
- (NSToolbarItem *) toolbar: (NSToolbar *)tb
      itemForItemIdentifier: (NSString *)ident
  willBeInsertedIntoToolbar: (BOOL)flag
{
  NSToolbarItem *item;
  NSButton *button;

  item = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: ident]);
  button = AUTORELEASE([[NSButton alloc]
    initWithFrame: NSMakeRect(0, 0, 24, 24)]);
  [item setLabel: [ident isEqualToString: @"short"]
    ? @"A" : @"A label much wider than the view"];
  [item setView: button];
  [item setMinSize: NSMakeSize(24, 24)];
  [item setMaxSize: NSMakeSize(24, 24)];
  return item;
}
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObjects: @"short", @"long", nil];
}
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)tb
{
  return [self toolbarAllowedItemIdentifiers: tb];
}
@end

int
main(int argc, char **argv)
{
  START_SET("NSToolbarItem icon only view width")

  {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *args = [NSMutableDictionary dictionaryWithDictionary:
      [defs volatileDomainForName: NSArgumentDomain]];

    [args setObject: @"GNUstep" forKey: @"GSTheme"];
    [args setObject: @"1" forKey: @"GSScaleFactor"];
    [defs removeVolatileDomainForName: NSArgumentDomain];
    [defs setVolatileDomain: args forName: NSArgumentDomain];
  }

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        {
          SKIP("It looks like GNUstep backend is not yet installed")
        }
    }
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *window;
      NSToolbar *toolbar;
      IOWDelegate *delegate = AUTORELEASE([IOWDelegate new]);
      CGFloat shortWidth;
      CGFloat longWidth;

      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(100, 100, 400, 100)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [window setReleasedWhenClosed: NO];
      toolbar = AUTORELEASE([[NSToolbar alloc]
        initWithIdentifier: @"IconOnlyViewWidth"]);
      [toolbar setDelegate: delegate];
      [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
      [window setToolbar: toolbar];
      [window orderFront: nil];
      [window display];

      shortWidth = NSWidth([[[[[toolbar items] objectAtIndex: 0] view]
        superview] frame]);
      longWidth = NSWidth([[[[[toolbar items] objectAtIndex: 1] view]
        superview] frame]);
      printf("icon only: view 24 pt, item with label \"A\" %g pt, "
        "item with a long label %g pt\n", shortWidth, longWidth);
      PASS(shortWidth == longWidth,
        "items with views of the same width are equally wide");
      PASS(shortWidth < 60,
        "an item with a view is not padded to the image item width");
      [window orderOut: nil];
      [window setToolbar: nil];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        {
          SKIP("No display available")
        }
      [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSToolbarItem icon only view width")

  return 0;
}
