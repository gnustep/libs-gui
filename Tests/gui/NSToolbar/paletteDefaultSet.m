#include "Testing.h"

#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>

#include <AppKit/NSApplication.h>
#include <AppKit/NSDragging.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSToolbar.h>
#include <AppKit/NSToolbarItem.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>

@interface NSToolbar (Private)
- (NSView *) _toolbarView;
@end

@interface PDSDelegate : NSObject
@end

@implementation PDSDelegate
- (NSToolbarItem *) toolbar: (NSToolbar *)tb
      itemForItemIdentifier: (NSString *)ident
  willBeInsertedIntoToolbar: (BOOL)flag
{
  NSToolbarItem *item;

  item = AUTORELEASE([[NSToolbarItem alloc] initWithItemIdentifier: ident]);
  [item setLabel: ident];
  [item setImage: [NSApp applicationIconImage]];
  return item;
}
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObjects: @"One", @"Two", @"Three",
    NSToolbarFlexibleSpaceItemIdentifier,
    NSToolbarCustomizeToolbarItemIdentifier, nil];
}
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)tb
{
  return [NSArray arrayWithObjects: @"One", @"Two",
    NSToolbarFlexibleSpaceItemIdentifier,
    NSToolbarCustomizeToolbarItemIdentifier, nil];
}
@end

@interface PDSDraggingInfo : NSObject
{
  NSPasteboard *_pasteboard;
}
- (id) initWithPasteboard: (NSPasteboard *)pasteboard;
@end

@implementation PDSDraggingInfo
- (id) initWithPasteboard: (NSPasteboard *)pasteboard
{
  if ((self = [super init]) != nil)
    ASSIGN(_pasteboard, pasteboard);
  return self;
}
- (void) dealloc
{
  RELEASE(_pasteboard);
  [super dealloc];
}
- (NSPasteboard *) draggingPasteboard
{
  return _pasteboard;
}
- (NSDragOperation) draggingSourceOperationMask
{
  return NSDragOperationCopy;
}
- (NSPoint) draggingLocation
{
  return NSMakePoint(10, 10);
}
- (id) draggingSource
{
  return nil;
}
@end

static NSView *
findView(NSView *view, NSString *className)
{
  NSEnumerator *e;
  NSView *sub;

  if ([NSStringFromClass([view class]) isEqualToString: className])
    return view;
  e = [[view subviews] objectEnumerator];
  while ((sub = [e nextObject]) != nil)
    {
      NSView *found = findView(sub, className);

      if (found != nil)
        return found;
    }
  return nil;
}

int
main(int argc, char **argv)
{
  START_SET("NSToolbar default set in the customization palette")

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
        SKIP("It looks like GNUstep backend is not yet installed")
    }
  NS_ENDHANDLER

  NS_DURING
    {
      PDSDelegate *delegate = AUTORELEASE([PDSDelegate new]);
      NSWindow *window;
      NSToolbar *toolbar;
      NSView *toolbarView;
      NSView *setView = nil;
      NSPasteboard *pboard;
      PDSDraggingInfo *info;
      NSString *type = @"GSDefaultToolbarSetPboardType";
      NSEnumerator *e;
      NSWindow *w;
      BOOL accepted = NO;

      window = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(100, 100, 500, 100)
                  styleMask: NSTitledWindowMask
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [window setReleasedWhenClosed: NO];
      toolbar = AUTORELEASE([[NSToolbar alloc]
        initWithIdentifier: @"PaletteDefaultSet"]);
      [toolbar setDelegate: delegate];
      [toolbar setAllowsUserCustomization: YES];
      [window setToolbar: toolbar];
      [window orderFront: nil];
      [window display];

      [toolbar runCustomizationPalette: nil];
      e = [[NSApp windows] objectEnumerator];
      while (setView == nil && (w = [e nextObject]) != nil)
        {
          if (w != window)
            setView = findView([w contentView], @"GSToolbarDefaultSetView");
        }
      printf("default set row in the palette: %s, %lu items\n",
        setView != nil ? "shown" : "missing",
        (unsigned long)[[setView subviews] count]);
      PASS(setView != nil && [[setView subviews] count] == 4,
        "the palette shows the four default items as one row");

      while ([[toolbar items] count] > 0)
        [toolbar removeItemAtIndex: 0];
      [toolbar insertItemWithItemIdentifier: @"Three" atIndex: 0];

      toolbarView = [toolbar _toolbarView];
      pboard = [NSPasteboard pasteboardWithUniqueName];
      [pboard declareTypes: [NSArray arrayWithObject: type] owner: nil];
      [pboard setString: @"default" forType: type];
      info = AUTORELEASE([[PDSDraggingInfo alloc] initWithPasteboard: pboard]);
      if ([[toolbarView registeredDraggedTypes] containsObject: type])
        {
          if ([(id)toolbarView draggingEntered: (id)info] != NSDragOperationNone
            && [(id)toolbarView prepareForDragOperation: (id)info])
            accepted = [(id)toolbarView performDragOperation: (id)info];
        }
      printf("toolbar after dropping the default set: %s\n",
        [[[[toolbar items] valueForKey: @"itemIdentifier"]
          componentsJoinedByString: @", "] UTF8String]);
      PASS(accepted, "the toolbar accepts the default set");
      PASS_EQUAL([[toolbar items] valueForKey: @"itemIdentifier"],
        [delegate toolbarDefaultItemIdentifiers: toolbar],
        "dropping the default set restores the default items");
      [pboard releaseGlobally];
      [window orderOut: nil];
    }
  NS_HANDLER
    {
      if ([[localException name] isEqualToString: NSInternalInconsistencyException]
        || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
        SKIP("No display available")
      [localException raise];
    }
  NS_ENDHANDLER

  END_SET("NSToolbar default set in the customization palette")

  return 0;
}
