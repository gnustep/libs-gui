#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSString.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSBitmapImageRep.h>

@interface RTVDS : NSObject
@end
@implementation RTVDS
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv { return 3; }
- (id) tableView: (NSTableView *)tv
       objectValueForTableColumn: (NSTableColumn *)col
       row: (NSInteger)row
{ return [NSString stringWithFormat: @"r%ld", (long)row]; }
@end

int
main(int argc, const char **argv)
{
  CREATE_AUTORELEASE_POOL(arp);
  START_SET("NSTableView rendering")

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
      NSTableView *tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 80)]);
      NSTableColumn *col = AUTORELEASE([[NSTableColumn alloc]
        initWithIdentifier: @"a"]);
      [col setWidth: 100.0];
      [tv addTableColumn: col];
      [tv setDataSource: AUTORELEASE([RTVDS new])];
      [tv reloadData];
      [w setContentView: tv];

      /* The table draws its rows and grid without error and produces a bitmap
         of its own size (a render regression lock, not a pixel comparison
         against AppKit). */
      [tv lockFocus];
      [tv drawRect: [tv bounds]];
      NSBitmapImageRep *rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: NSMakeRect(0, 0, 120, 80)]);
      [tv unlockFocus];

      PASS(rep != nil && [rep pixelsWide] == 120 && [rep pixelsHigh] == 80,
        "a table renders into a bitmap of its bounds");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
  NS_ENDHANDLER

  END_SET("NSTableView rendering")
  DESTROY(arp);
  return 0;
}
