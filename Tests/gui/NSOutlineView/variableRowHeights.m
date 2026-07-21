#import "ObjectTesting.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSOutlineView.h>
#import <AppKit/NSTableColumn.h>

@interface TestDataSource : NSObject <NSOutlineViewDataSource>
{
  NSArray *rootItems;
  NSDictionary *childrenDict;
}
@end

@implementation TestDataSource

- (id) init
{
  self = [super init];
  if (self)
    {
      rootItems = [[NSArray alloc] initWithObjects: @"Root1", @"Root2", @"Root3", nil];
      childrenDict = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSArray arrayWithObjects: @"Child1-1", @"Child1-2", nil], @"Root1",
        [NSArray arrayWithObjects: @"Child2-1", nil], @"Root2",
        nil];
    }
  return self;
}

- (void) dealloc
{
  [rootItems release];
  [childrenDict release];
  [super dealloc];
}

- (NSInteger) outlineView: (NSOutlineView *)outlineView
  numberOfChildrenOfItem: (id)item
{
  if (item == nil)
    return [rootItems count];
  
  NSArray *children = [childrenDict objectForKey: item];
  return children ? [children count] : 0;
}

- (id) outlineView: (NSOutlineView *)outlineView
             child: (NSInteger)index
            ofItem: (id)item
{
  if (item == nil)
    return [rootItems objectAtIndex: index];
  
  NSArray *children = [childrenDict objectForKey: item];
  return [children objectAtIndex: index];
}

- (BOOL) outlineView: (NSOutlineView *)outlineView
    isItemExpandable: (id)item
{
  return [childrenDict objectForKey: item] != nil;
}

- (id) outlineView: (NSOutlineView *)outlineView
  objectValueForTableColumn: (NSTableColumn *)tableColumn
            byItem: (id)item
{
  return item;
}

@end

@interface TestDelegate : NSObject <NSOutlineViewDelegate>
{
  BOOL useVariableHeights;
  BOOL customSizeToFitCalled;
  NSInteger lastSizeToFitColumn;
}
- (BOOL) useVariableHeights;
- (void) setUseVariableHeights: (BOOL)flag;
- (BOOL) customSizeToFitCalled;
- (NSInteger) lastSizeToFitColumn;
@end

@implementation TestDelegate

- (id) init
{
  self = [super init];
  if (self)
    {
      useVariableHeights = NO;
      customSizeToFitCalled = NO;
      lastSizeToFitColumn = -1;
    }
  return self;
}

- (BOOL) useVariableHeights
{
  return useVariableHeights;
}

- (void) setUseVariableHeights: (BOOL)flag
{
  useVariableHeights = flag;
}

- (BOOL) customSizeToFitCalled
{
  return customSizeToFitCalled;
}

- (NSInteger) lastSizeToFitColumn
{
  return lastSizeToFitColumn;
}

- (CGFloat) outlineView: (NSOutlineView *)outlineView
      heightOfRowByItem: (id)item
{
  if (!useVariableHeights)
    return [outlineView rowHeight];
  
  // Return different heights based on item
  if ([item hasPrefix: @"Root"])
    return 30.0;
  else if ([item hasPrefix: @"Child"])
    return 20.0;
  
  return [outlineView rowHeight];
}

- (CGFloat) outlineView: (NSOutlineView *)outlineView
  sizeToFitWidthOfColumn: (NSInteger)column
{
  customSizeToFitCalled = YES;
  lastSizeToFitColumn = column;
  
  // Return a custom width
  return 150.0;
}

@end

int main()
{
  NSAutoreleasePool *arp = [NSAutoreleasePool new];
  NSOutlineView *outlineView;
  TestDataSource *dataSource;
  TestDelegate *delegate;
  NSTableColumn *column;

  START_SET("NSOutlineView variable row heights")

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

  // Create outline view
  outlineView = [[NSOutlineView alloc] initWithFrame: NSMakeRect(0, 0, 300, 400)];
  column = [[NSTableColumn alloc] initWithIdentifier: @"TestColumn"];
  [column setWidth: 100.0];
  [outlineView addTableColumn: column];
  [outlineView setOutlineTableColumn: column];
  [column release];

  dataSource = [[TestDataSource alloc] init];
  delegate = [[TestDelegate alloc] init];
  
  [outlineView setDataSource: dataSource];
  [outlineView setDelegate: delegate];
  [outlineView setRowHeight: 16.0];
  
  // Test 1: Basic setup without variable heights
  [outlineView reloadData];
  
  pass([outlineView numberOfRows] == 3,
       "outline view has correct number of root rows");
  
  // Expand first item
  [outlineView expandItem: @"Root1"];
  pass([outlineView numberOfRows] == 5,
       "outline view has correct number of rows after expanding");
  
  // Test 2: Row height with uniform heights
  {
    NSRect rect0 = [outlineView rectOfRow: 0];
    NSRect rect1 = [outlineView rectOfRow: 1];
    
    pass(rect0.size.height == 16.0,
         "row 0 has default height when delegate doesn't return variable heights");
    pass(rect1.size.height == 16.0,
         "row 1 has default height when delegate doesn't return variable heights");
    pass(rect1.origin.y == rect0.origin.y + 16.0,
         "row 1 starts after row 0 with uniform heights");
  }
  
  // Test 3: Enable variable heights
  [delegate setUseVariableHeights: YES];
  [outlineView reloadData];
  [outlineView expandItem: @"Root1"];
  
  {
    NSRect rect0 = [outlineView rectOfRow: 0]; // Root1
    NSRect rect1 = [outlineView rectOfRow: 1]; // Child1-1
    NSRect rect2 = [outlineView rectOfRow: 2]; // Child1-2
    NSRect rect3 = [outlineView rectOfRow: 3]; // Root2
    
    pass(rect0.size.height == 30.0,
         "root item has height 30.0 from delegate");
    pass(rect1.size.height == 20.0,
         "child item has height 20.0 from delegate");
    pass(rect1.origin.y == rect0.origin.y + 30.0,
         "child row starts after root with variable height");
    pass(rect2.origin.y == rect1.origin.y + 20.0,
         "second child row positioned correctly");
    pass(rect3.origin.y == rect2.origin.y + 20.0,
         "next root row positioned after children with variable heights");
  }
  
  // Test 4: rowAtPoint with variable heights
  {
    NSRect rect1 = [outlineView rectOfRow: 1];
    NSPoint midPoint = NSMakePoint(10, rect1.origin.y + rect1.size.height / 2);
    NSInteger rowAtMid = [outlineView rowAtPoint: midPoint];
    
    pass(rowAtMid == 1,
         "rowAtPoint correctly identifies row with variable heights");
  }
  
  // Test 5: frameOfCellAtColumn with variable heights
  {
    NSRect cellFrame0 = [outlineView frameOfCellAtColumn: 0 row: 0];
    NSRect cellFrame1 = [outlineView frameOfCellAtColumn: 0 row: 1];
    
    pass(cellFrame0.size.height > 0 && cellFrame0.size.height <= 30.0,
         "cell frame height respects row height for root item");
    pass(cellFrame1.size.height > 0 && cellFrame1.size.height <= 20.0,
         "cell frame height respects row height for child item");
  }
  
  // Test 6: sizeToFitWidthOfColumn delegate method
  {
    pass([delegate customSizeToFitCalled] == NO,
         "sizeToFitWidthOfColumn not called yet");
    
    // Simulate double-click on column header
    [outlineView _sendDoubleActionForColumn: 0];
    
    pass([delegate customSizeToFitCalled] == YES,
         "sizeToFitWidthOfColumn called on double-click");
    pass([delegate lastSizeToFitColumn] == 0,
         "correct column index passed to delegate");
    
    NSTableColumn *col = [[outlineView tableColumns] objectAtIndex: 0];
    pass([col width] == 150.0,
         "column width set to value returned by delegate");
  }
  
  // Test 7: Total height calculation with variable heights
  {
    // Calculate expected total height
    // Root1 (30) + Child1-1 (20) + Child1-2 (20) + Root2 (30) + Root3 (30) = 130
    CGFloat expectedHeight = 30.0 + 20.0 + 20.0 + 30.0 + 30.0;
    NSRect boundsRect = [outlineView bounds];
    
    // The frame should accommodate all rows plus grid line
    pass(boundsRect.size.height >= expectedHeight,
         "total height accounts for variable row heights");
  }
  
  // Cleanup
  [outlineView release];
  [dataSource release];
  [delegate release];

  END_SET("NSOutlineView variable row heights")

  [arp release];
  return 0;
}
