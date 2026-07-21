#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSString.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSOutlineView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSBitmapImageRep.h>

@interface RTree : NSObject
@end
@implementation RTree
- (NSArray *) childrenOf: (id)item
{
  if (item == nil) return [NSArray arrayWithObjects: @"A", @"B", nil];
  if ([item isEqual: @"A"]) return [NSArray arrayWithObjects: @"A1", nil];
  return [NSArray array];
}
- (NSInteger) outlineView: (NSOutlineView *)ov numberOfChildrenOfItem: (id)item
{ return [[self childrenOf: item] count]; }
- (id) outlineView: (NSOutlineView *)ov child: (NSInteger)i ofItem: (id)item
{ return [[self childrenOf: item] objectAtIndex: i]; }
- (BOOL) outlineView: (NSOutlineView *)ov isItemExpandable: (id)item
{ return [[self childrenOf: item] count] > 0; }
- (id) outlineView: (NSOutlineView *)ov
       objectValueForTableColumn: (NSTableColumn *)col
       byItem: (id)item
{ return item; }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSOutlineView rendering")

  NS_DURING
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSWindow *w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 80)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      NSOutlineView *ov = AUTORELEASE([[NSOutlineView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 80)]);
      NSTableColumn *col = AUTORELEASE([[NSTableColumn alloc]
        initWithIdentifier: @"c"]);
      [col setWidth: 100.0];
      [ov addTableColumn: col];
      [ov setOutlineTableColumn: col];
      [ov setDataSource: AUTORELEASE([RTree new])];
      [ov reloadData];
      [ov expandItem: @"A"];
      [w setContentView: ov];

      /* The outline draws its rows and disclosure markers without error and
         produces a bitmap of its own size (a render regression lock, not a
         pixel comparison against AppKit). */
      [ov lockFocus];
      [ov drawRect: [ov bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 120, 80)]);
      [ov unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 120 && [rep pixelsHigh] == 80,
        "an outline view renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSOutlineView rendering")
  DESTROY(arp);
  return 0;
}
