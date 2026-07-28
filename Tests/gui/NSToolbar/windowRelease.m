/* A window that carries a toolbar can be released without being closed. The
   toolbar registers with the validation center for the window it is shown in,
   and that registration has to go away with the window rather than leave a
   pointer to it behind. */
#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSString.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSToolbar.h>
#include <AppKit/NSToolbarItem.h>
#include <AppKit/NSWindow.h>

@interface TBReleaseDelegate : NSObject
@end

@implementation TBReleaseDelegate
- (NSToolbarItem *) toolbar: (NSToolbar *)tb
      itemForItemIdentifier: (NSString *)ident
  willBeInsertedIntoToolbar: (BOOL)flag
{
  return AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: ident]);
}
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObject: @"only"];
}
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObject: @"only"];
}
@end

static NSWindow *
buildWindowWithToolbar(NSString *identifier)
{
  NSWindow *w = AUTORELEASE([[NSWindow alloc]
    initWithContentRect: NSMakeRect(0, 0, 300, 200)
              styleMask: NSTitledWindowMask
                backing: NSBackingStoreBuffered
                  defer: NO]);
  NSToolbar *t = AUTORELEASE([[NSToolbar alloc]
    initWithIdentifier: identifier]);

  [t setDelegate: AUTORELEASE([[TBReleaseDelegate alloc] init])];
  [w setToolbar: t];

  return w;
}

int
main(int argc, char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  NSAutoreleasePool *inner;
  NSWindow *w;

  START_SET("NSToolbar window release")

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
      /* The window and its toolbar go away here without -close being called,
         which is what leaves a stale registration behind. */
      inner = [NSAutoreleasePool new];
      w = buildWindowWithToolbar(@"released");
      PASS([[[w toolbar] items] count] == 1,
        "the toolbar shown in the window has the item its delegate offers");
      RELEASE(inner);

      /* Reaching this point at all means the drain above did not read the
         released window back. A second window has to work as the first did,
         which it cannot if a stale entry is still held for the old one. */
      w = buildWindowWithToolbar(@"replacement");
      PASS([[[w toolbar] items] count] == 1,
        "a later window still builds its toolbar after the first is released");
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

  END_SET("NSToolbar window release")

  DESTROY(arp);
  return 0;
}
