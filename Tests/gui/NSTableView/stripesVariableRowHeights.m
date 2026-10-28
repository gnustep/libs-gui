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
#import <AppKit/NSOutlineView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSWindow.h>

/* Rows of different heights (from -outlineView:heightOfRowByItem:, the
 * variable row height the table views here support) followed by the
 * stripes drawn below the last row at the standard row height.
 */

static const CGFloat heights[3] = { 16.0, 40.0, 28.0 };

@interface SVRHDS : NSObject
{
  NSArray *items;
}
@end

@implementation SVRHDS
- (id) init
{
  if ((self = [super init]) != nil)
    {
      items = [[NSArray alloc] initWithObjects: @"a", @"b", @"c", nil];
    }
  return self;
}
- (void) dealloc
{
  RELEASE(items);
  [super dealloc];
}
- (NSInteger) outlineView: (NSOutlineView *)ov
   numberOfChildrenOfItem: (id)item
{
  return item == nil ? [items count] : 0;
}
- (id) outlineView: (NSOutlineView *)ov child: (NSInteger)index ofItem: (id)item
{
  return [items objectAtIndex: index];
}
- (BOOL) outlineView: (NSOutlineView *)ov isItemExpandable: (id)item
{
  return NO;
}
- (id) outlineView: (NSOutlineView *)ov
  objectValueForTableColumn: (NSTableColumn *)col
	    byItem: (id)item
{
  return item;
}
- (CGFloat) outlineView: (NSOutlineView *)ov heightOfRowByItem: (id)item
{
  return heights[[items indexOfObject: item]];
}
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

/* The stripe index at y: the rows first, then standard height stripes. */
static NSInteger
stripeAt(CGFloat y, CGFloat rowHeight)
{
  CGFloat top = 0.0;
  NSInteger i;

  for (i = 0; i < 3; i++)
    {
      if (y < top + heights[i])
	{
	  return i;
	}
      top += heights[i];
    }
  return 3 + (NSInteger)floor((y - top) / rowHeight);
}

/* Redraws only r (after covering the table in a color no stripe has)
 * and returns the number of pixel rows inside r whose color at x is
 * not the stripe expected there.
 */
static NSInteger
wrongRowsAfterRedrawing(NSOutlineView *ov, NSRect r, NSArray *rowColors)
{
  NSBitmapImageRep *rep;
  NSInteger wrong = 0;
  NSInteger y;

  [ov lockFocus];
  [[NSColor redColor] set];
  NSRectFill([ov bounds]);
  NSRectClip(r);
  [ov drawRect: r];
  rep = AUTORELEASE([[NSBitmapImageRep alloc]
    initWithFocusedViewRect: [ov bounds]]);
  [ov unlockFocus];

  for (y = (NSInteger)NSMinY(r); y < (NSInteger)NSMaxY(r); y++)
    {
      NSInteger s = stripeAt(y + 0.5, [ov rowHeight]);
      NSColor *expected = [rowColors objectAtIndex: s % [rowColors count]];

      if (!sameColor([rep colorAtX: 110 y: y], expected))
	{
	  if (wrong == 0)
	    {
	      printf("  first wrong pixel row at y = %ld (stripe %ld)\n",
		(long)y, (long)s);
	    }
	  wrong++;
	}
    }
  return wrong;
}

int
main(int argc, const char **argv)
{
  START_SET("NSTableView stripes with variable row heights")

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
      {
        SKIP("It looks like GNUstep backend is not yet installed")
      }
  NS_ENDHANDLER

  NS_DURING
    {
      NSArray *rowColors = [NSColor controlAlternatingRowBackgroundColors];
      NSScrollView *sv = AUTORELEASE([[NSScrollView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 160)]);
      NSOutlineView *ov = AUTORELEASE([[NSOutlineView alloc]
        initWithFrame: NSMakeRect(0, 0, 120, 160)]);
      NSTableColumn *col = AUTORELEASE([[NSTableColumn alloc]
        initWithIdentifier: @"a"]);
      SVRHDS *ds = AUTORELEASE([SVRHDS new]);
      NSWindow *w;
      CGFloat rowsEnd;
      CGFloat height;
      NSRect full;
      NSRect lower;
      NSRect middle;

      w = AUTORELEASE([[NSWindow alloc]
        initWithContentRect: NSMakeRect(0, 0, 120, 160)
                  styleMask: NSWindowStyleMaskBorderless
                    backing: NSBackingStoreBuffered
                      defer: NO]);
      [col setWidth: 100.0];
      [ov addTableColumn: col];
      [ov setOutlineTableColumn: col];
      [ov setUsesAlternatingRowBackgroundColors: YES];
      [ov setDrawsGrid: NO];
      [ov setDataSource: (id)ds];
      [ov setDelegate: (id)ds];
      [w setContentView: sv];
      [sv setDocumentView: ov];
      [ov reloadData];

      rowsEnd = NSMaxY([ov rectOfRow: 2]);
      height = NSHeight([ov bounds]);
      full = [ov bounds];
      lower = NSMakeRect(0, rowsEnd + 6, NSWidth(full), height - rowsEnd - 6);
      middle = NSMakeRect(0, 30, NSWidth(full), 70);
      printf("rows end at %g, standard row height %g, table is %g high\n",
        rowsEnd, [ov rowHeight], height);

      PASS([ov numberOfRows] == 3
        && NSHeight([ov rectOfRow: 1]) == 40.0
        && rowsEnd == 84.0,
        "the rows have the heights given by the delegate");
      PASS(height >= rowsEnd + 3 * [ov rowHeight],
        "the table covers its clip view well below the last row");
      PASS([rowColors count] == 2
        && !sameColor([rowColors objectAtIndex: 0], [rowColors objectAtIndex: 1]),
        "there are two distinct alternating row colors");
      PASS(wrongRowsAfterRedrawing(ov, full, rowColors) == 0,
        "a full redraw paints a stripe per row and standard height stripes below");
      PASS(wrongRowsAfterRedrawing(ov, lower, rowColors) == 0,
        "redrawing only the area below the last row paints the same stripes");
      PASS(wrongRowsAfterRedrawing(ov, middle, rowColors) == 0,
        "redrawing only the middle of the table paints the same stripes");
    }
  NS_HANDLER
    if ([[localException name] isEqualToString: NSInternalInconsistencyException]
      || [[localException name] isEqualToString: @"NSWindowServerCommunicationException"])
      {
        SKIP("No display available")
      }
    [localException raise];
  NS_ENDHANDLER

  END_SET("NSTableView stripes with variable row heights")
  return 0;
}
