/* Toolbars built with -init all carry the same empty identifier, so they must
   not be taken for each other's configuration model: each one builds the items
   its own delegate offers. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbar.h>
#include <AppKit/NSToolbarItem.h>

@interface TBFirstDelegate : NSObject
@end

@implementation TBFirstDelegate
- (NSToolbarItem *) toolbar: (NSToolbar *)tb
      itemForItemIdentifier: (NSString *)ident
  willBeInsertedIntoToolbar: (BOOL)flag
{
  return AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: ident]);
}
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObjects: @"first", @"second", nil];
}
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObject: @"first"];
}
@end

@interface TBSecondDelegate : TBFirstDelegate
@end

@implementation TBSecondDelegate
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObject: @"second"];
}
@end

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSToolbar *t1;
  NSToolbar *t2;

  START_SET("NSToolbar default identifier items")

  NS_DURING
    {
      [NSApplication sharedApplication];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException])
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NS_DURING
    {
      t1 = AUTORELEASE([[NSToolbar alloc] init]);
      [t1 setDelegate: AUTORELEASE([[TBFirstDelegate alloc] init])];

      t2 = AUTORELEASE([[NSToolbar alloc] init]);
      [t2 setDelegate: AUTORELEASE([[TBSecondDelegate alloc] init])];

      PASS([[[t1 items] valueForKey: @"itemIdentifier"]
             isEqual: [NSArray arrayWithObject: @"first"]],
        "a toolbar built with -init shows the items its delegate offers");
      PASS([[[t2 items] valueForKey: @"itemIdentifier"]
             isEqual: [NSArray arrayWithObject: @"second"]],
        "a second toolbar built with -init shows its own delegate's items");
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

  END_SET("NSToolbar default identifier items")

  DESTROY(arp);
  return 0;
}
