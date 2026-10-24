#import "Testing.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSBitmapImageRep.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSWindow.h>

@interface SBLRDS : NSObject
@end
@implementation SBLRDS
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv { return 3; }
- (id) tableView: (NSTableView *)tv
       objectValueForTableColumn: (NSTableColumn *)col
       row: (NSInteger)row
{ return [NSString stringWithFormat: @"r%ld", (long)row]; }
@end

static BOOL
sameColor(NSColor *a, NSColor *b)
{
  a = [a colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  b = [b colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  return fabs([a redComponent] - [b redComponent]) < 0.02
    && fabs([a greenComponent] - [b greenComponent]) < 0.02
    && fabs([a blueComponent] - [b blueComponent]) < 0.02;
}

int
main(int argc, const char **argv)
{
  START_SET("NSTableView stripes below the last row")

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
    [NSApplication sharedApplication];
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException])
      SKIP("It looks like GNUstep backend is not yet installed")
  NS_ENDHANDLER

  NS_DURING
    {
      NSArray *rowColors = [NSColor controlAlternatingRowBackgroundColors];
      NSScrollView *sv = AUTORELEASE([[NSScrollView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 160)]);
      NSTableView *tv = AUTORELEASE([[NSTableView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 160)]);
      NSTableColumn *col = AUTORELEASE([[NSTableColumn alloc]
        initWithIdentifier: @"a"]);
      NSWindow *w;
      NSBitmapImageRep *rep;
      NSRect below;
      CGFloat h;
      NSColor *c3;
      NSColor *c4;
      NSColor *c5;

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 160)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [col setWidth: 100.0];
      [tv addTableColumn: col];
      [tv setUsesAlternatingRowBackgroundColors: YES];
      [tv setDataSource: AUTORELEASE([SBLRDS new])];
      [w setContentView: sv];
      [sv setDocumentView: tv];
      [tv reloadData];
      h = [tv rowHeight];

      below = NSMakeRect(0, 3 * h, NSWidth([tv bounds]), 3 * h);
      printf("rows end at %g, table is %g high, redrawn %g to %g\n",
        3 * h, NSHeight([tv bounds]), NSMinY(below), NSMaxY(below));
      [tv lockFocus];
      NSRectClip(below);
      [tv drawRect: below];
      rep = AUTORELEASE([[NSBitmapImageRep alloc]
        initWithFocusedViewRect: [tv bounds]]);
      [tv unlockFocus];

      c3 = [rep colorAtX: 110 y: (NSInteger)(3.5 * h)];
      c4 = [rep colorAtX: 110 y: (NSInteger)(4.5 * h)];
      c5 = [rep colorAtX: 110 y: (NSInteger)(5.5 * h)];

      PASS(NSMaxY(below) <= NSHeight([tv bounds]),
        "the table covers its clip view below the last row");
      PASS([rowColors count] == 2
        && !sameColor([rowColors objectAtIndex: 0], [rowColors objectAtIndex: 1]),
        "there are two distinct alternating row colours");
      PASS(!sameColor(c3, c4) && sameColor(c3, c5),
        "the rows drawn below the last row alternate");
      PASS(sameColor(c3, [rowColors objectAtIndex: 1])
        && sameColor(c4, [rowColors objectAtIndex: 0]),
        "the stripes below the last row continue those of the rows above");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      SKIP("No display available")
    [localException raise];
  NS_ENDHANDLER

  END_SET("NSTableView stripes below the last row")
  return 0;
}
