#include <AppKit/NSTabView.h>

@implementation NSTabView
- (id)initWithFrame:(NSRect)rect
{
  [super initWithFrame:rect];

  // setup variables  

  tab_items = [NSMutableArray new];

  return self;
}

// tab management.

- (void)addTabViewItem:(NSTabViewItem *)tabViewItem
{
  [tab_items insertObject:tabViewItem atIndex:[tab_items count]];
}

- (void)insertTabViewItem:(NSTabViewItem *)tabViewItem
		  atIndex:(int)index
{
  [tab_items insertObject:tabViewItem atIndex:index];
}

- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem
{
  int i = [tab_items indexOfObject:tabViewItem];
  
  if (i == -1)
    return;

  [tab_items removeObjectAtIndex:i];
}

- (int)indexOfTabViewItem:(NSTabViewItem *)tabViewItem
{
  return [tab_items indexOfObject:tabViewItem];
}

- (int)indexOfTabViewItemWithIdentifier:(id)identifier
{
  // the spec is confusing on this method.
  return 0;
}

- (int)numberOfTabViewItems
{
  return [tab_items count];
}

- (NSTabViewItem *)tabViewItemAtIndex:(int)index
{
  return [tab_items objectAtIndex:index];
}

- (NSArray *)tabViewItems
{
  return (NSArray *)tab_items;
}

- (void)selectFirstTabViewItem:(id)sender
{
  [self selectTabViewItemAtIndex:0];
}

- (void)selectLastTabViewItem:(id)sender
{
  [self selectTabViewItem:[tab_items lastObject]];
}

- (void)selectNextTabViewItem:(id)sender
{
  [self selectTabViewItemAtIndex:tab_selected_item+1];
}

- (void)selectPreviousTabViewItem:(id)sender
{
  [self selectTabViewItemAtIndex:tab_selected_item-1];
}

- (void)selectTabViewItem:(NSTabViewItem *)tabViewItem
{
}

- (void)selectTabViewItemAtIndex:(int)index
{
}

- (void)takeSelectedTabViewItemFromSender:(id)sender
{
}

- (void)setFont:(NSFont *)font
{
  ASSIGN(tab_font, font);
}

- (NSFont *)font
{
  return tab_font;
}

- (void)setTabViewType:(NSTabViewType)tabViewType
{
  tab_type = tabViewType;
}

- (NSTabViewType)tabViewType
{
  return tab_type;
}

- (void)setDrawsBackground:(BOOL)flag
{
  tab_draws_background = flag;
}

- (BOOL) drawsBackground
{
  return tab_draws_background;
}

- (void)setAllowsTruncatedLabels:(BOOL)allowTruncatedLabels
{
  tab_truncated_label = allowTruncatedLabels;
}

- (BOOL)allowsTruncatedLabels
{
  return tab_truncated_label;
}

- (void)setDelegate:(id)anObject
{
  ASSIGN(tab_delegate, anObject);
}

- (id)delegate
{
  return tab_delegate;
}

// content and size

- (NSSize)minimumSize
{
  return NSZeroSize;
}

- (NSRect)contentRect
{
  return NSZeroRect;
}

// Event handling.

- (NSTabViewItem *)tabViewItemAtPoint:(NSPoint)point
{
  return nil;
}

// Coding.

- (void) encodeWithCoder: (NSCoder*)aCoder
{ 
  [super encodeWithCoder: aCoder];
           
  [aCoder encodeObject:tab_items];
  [aCoder encodeObject:tab_font];
  [aCoder encodeValueOfObjCType: @encode(NSTabViewType) at: &tab_type];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tab_draws_background];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tab_truncated_label];
  [aCoder encodeObject:tab_delegate];
  [aCoder encodeValueOfObjCType: "i" at: &tab_selected_item];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &tab_items];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &tab_font];
  [aDecoder decodeValueOfObjCType: @encode(NSTabViewType) at:&tab_type];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tab_draws_background];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tab_truncated_label];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &tab_delegate];
  [aDecoder decodeValueOfObjCType: "i" at: &tab_selected_item];

  return self;
}
@end
