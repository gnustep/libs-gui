
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSTabViewItem.h>
#include <AppKit/PSOperators.h>

@implementation NSTabView
- (id)initWithFrame:(NSRect)rect
{
  [super initWithFrame:rect];

  // setup variables  

  tab_items = [NSMutableArray new];
  tab_font = [NSFont systemFontOfSize:12];
  tab_selected = nil;

  return self;
}

// tab management.

- (void)addTabViewItem:(NSTabViewItem *)tabViewItem
{
  [tabViewItem _setTabView:self];
  [tab_items insertObject:tabViewItem atIndex:[tab_items count]];
}

- (void)insertTabViewItem:(NSTabViewItem *)tabViewItem
		  atIndex:(int)index
{
  [tabViewItem _setTabView:self];
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

// Drawing.

- (void)drawRect:(NSRect)rect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  float borderThickness;
  int howMany = [tab_items count];
  int i;
  NSRect previousRect;
  NSTabState previousState;

  DPSgsave(ctxt);

  switch (tab_type) {
    case NSTopTabsBezelBorder:
      rect.size.height -= 20;
      NSDrawButton(rect, rect);
      borderThickness = 2;
      break;
    case NSNoTabsBezelBorder:
      NSDrawButton(rect, rect);
      borderThickness = 2;
      break;
    case NSNoTabsLineBorder:
      NSFrameRect(rect);
      borderThickness = 1;
      break;
    case NSNoTabsNoBorder:
      borderThickness = 0;
      break;
  }

  for (i=0;i<howMany;i++) {
    // where da tab be at?
    NSSize s;
    NSRect r;
    NSPoint iP;
    NSTabViewItem *anItem = [tab_items objectAtIndex:i];
    NSTabState itemState;

    // hack to simulate a selected tab other than tab one.
//    if (i == 0) [anItem _setTabState:NSSelectedTab];

    itemState = [anItem tabState];

    s = [anItem sizeOfLabel:NO];
    NSLog(@"Label: %@ Size: %d\n", [anItem label], (int)s.width);

    if (i == 0) {

      iP.x = rect.origin.x;
      iP.y = rect.size.height;

      if (itemState == NSSelectedTab)
        [[NSImage imageNamed:@"common_TabUnSelectedLeft.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
      else if (itemState == NSBackgroundTab)
        [[NSImage imageNamed:@"common_TabUnSelectedLeft.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
      else
	NSLog(@"Not finished yet. Luff ya.\n");

      r.origin.x = rect.origin.x + 13;
      r.origin.y = rect.size.height;
      r.size.width = s.width;
      r.size.height = 15;

      DPSsetlinewidth(ctxt,1);
      DPSsetgray(ctxt,1);
      DPSmoveto(ctxt, r.origin.x, r.origin.y+16);
      DPSrlineto(ctxt, r.size.width, 0);
      DPSstroke(ctxt);      

      [anItem drawLabel:NO inRect:r];

      previousRect = r;
      previousState = itemState;
    } else {
      iP.x = previousRect.origin.x + previousRect.size.width;
      iP.y = rect.size.height;

      if (itemState == NSSelectedTab) {
	iP.y -= 1;
        [[NSImage imageNamed:@"common_TabUnSelectToSelectedJunction.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
      }
      else if (itemState == NSBackgroundTab) {
	if (previousState == NSSelectedTab) {
	  iP.y -= 1;
          [[NSImage imageNamed:@"common_TabSelectedToUnSelectedJunction.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
	  iP.y += 1;
	} else {
          [[NSImage imageNamed:@"common_TabUnSelectedJunction.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
        }
      } 
      else
	NSLog(@"Not finished yet. Luff ya.\n");

      r.origin.x = iP.x + 13;
      r.origin.y = rect.size.height;
      r.size.width = s.width;
      r.size.height = 15;

      DPSsetlinewidth(ctxt,1);
      DPSsetgray(ctxt,1);
      DPSmoveto(ctxt, r.origin.x, r.origin.y+16);
      DPSrlineto(ctxt, r.size.width, 0);
      DPSstroke(ctxt);      

      [anItem drawLabel:NO inRect:r];

      previousRect = r;
      previousState = itemState;
    }  

    if (i == howMany-1) {
        iP.x += s.width + 13;

      if ([anItem tabState] == NSSelectedTab)
        [[NSImage imageNamed:@"common_TabSelectedRight.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
      else if ([anItem tabState] == NSBackgroundTab)
        [[NSImage imageNamed:@"common_TabUnSelectedRight.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
      else
	NSLog(@"Not finished yet. Luff ya.\n");
    }
  }

  DPSgrestore(ctxt);
}

// Event handling.

- (NSTabViewItem *)tabViewItemAtPoint:(NSPoint)point
{
  int howMany = [tab_items count];
  int i;

  for (i=0;i<howMany;i++) {
    NSTabViewItem *anItem = [tab_items objectAtIndex:i];

    if(NSPointInRect(point,[anItem _tabRect]))
      return anItem;
  }

  return nil;
}

- (NSView*) hitTest: (NSPoint)aPoint
{
  NSTabViewItem *anItem = [self tabViewItemAtPoint:aPoint];

  if (anItem) {
    if (tab_selected)
      [tab_selected _setTabState:NSBackgroundTab];

    tab_selected = anItem;
    [anItem _setTabState:NSSelectedTab];
  }

  [self setNeedsDisplay:YES];

  return [super hitTest:aPoint];
}

/*
- (BOOL) mouse: (NSPoint)aPoint inRect: (NSRect)aRect
{
}
*/

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
