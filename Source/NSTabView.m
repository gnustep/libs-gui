
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

  if ([tab_delegate respondsToSelector:
	@selector(tabViewDidChangeNumberOfTabViewItems:)])
    {
      [tab_delegate tabViewDidChangeNumberOfTabViewItems:self];
    }
}

- (void)insertTabViewItem:(NSTabViewItem *)tabViewItem
		  atIndex:(int)index
{
  [tabViewItem _setTabView:self];
  [tab_items insertObject:tabViewItem atIndex:index];

  if ([tab_delegate respondsToSelector:
	@selector(tabViewDidChangeNumberOfTabViewItems:)])
    {
      [tab_delegate tabViewDidChangeNumberOfTabViewItems:self];
    }
}

- (void)removeTabViewItem:(NSTabViewItem *)tabViewItem
{
  int i = [tab_items indexOfObject:tabViewItem];
  
  if (i == -1)
    return;

  [tab_items removeObjectAtIndex:i];

  if ([tab_delegate respondsToSelector:
	@selector(tabViewDidChangeNumberOfTabViewItems:)])
    {
      [tab_delegate tabViewDidChangeNumberOfTabViewItems:self];
    }
}

- (int)indexOfTabViewItem:(NSTabViewItem *)tabViewItem
{
  return [tab_items indexOfObject:tabViewItem];
}

- (int)indexOfTabViewItemWithIdentifier:(id)identifier
{
  int howMany = [tab_items count];
  int i;

  for (i=0;i<howMany;i++)
    {
      id anItem = [tab_items objectAtIndex:i];

      if ([[anItem identifier] isEqual:identifier])
        return i;
    }
  return NSNotFound;
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

- (NSTabViewItem *)selectedTabViewItem
{
  return [tab_items objectAtIndex:tab_selected_item];
}

- (void)selectTabViewItem:(NSTabViewItem *)tabViewItem
{
  BOOL canSelect = YES;

  if ([tab_delegate respondsToSelector:
    @selector(tabView:shouldSelectTabViewItem:)])
    {
      canSelect = [tab_delegate tabView:self
		    shouldSelectTabViewItem:tabViewItem];
    }

  if (canSelect)
    {
      if (tab_selected)
        {
          [tab_selected _setTabState:NSBackgroundTab];
          if ([tab_selected view])
	    [[tab_selected view] removeFromSuperview];
        }

        tab_selected = tabViewItem;

	if ([tab_delegate respondsToSelector:
	  @selector(tabView:willSelectTabViewItem:)])
	  {
	    [tab_delegate tabView:self willSelectTabViewItem:tab_selected];
          }

        tab_selected_item = [tab_items indexOfObject:tab_selected];
        [tab_selected _setTabState:NSSelectedTab];
        if ([tab_selected view])
          [self addSubview:[tab_selected view]];

	if ([tab_delegate respondsToSelector:
	  @selector(tabView:didSelectTabViewItem:)])
	  {
	    [tab_delegate tabView:self didSelectTabViewItem:tab_selected];
          }

	[self setNeedsDisplay:YES];
    }
}

- (void)selectTabViewItemAtIndex:(int)index
{
  [self selectTabViewItem:[tab_items objectAtIndex:index]];
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
  tab_delegate = anObject;
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
  NSRect cRect = frame;

  cRect.origin.x = 0;
  cRect.origin.y = 0;

  if (tab_type == NSTopTabsBezelBorder)
    {
      cRect.origin.y = 0;
      cRect.size.height -= 16;
    }

  if (tab_type == NSBottomTabsBezelBorder)
    {
      NSLog(@"hehehe. %f", cRect.origin.y);
      cRect.size.height -= 8;
      cRect.origin.y = 8;
    }

  return cRect;
}

// Drawing.

- (void)drawRect:(NSRect)rect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  float borderThickness;
  int howMany = [tab_items count];
  int i;
  NSRect previousRect;
  int previousState = 0;

  rect = NSIntersectionRect(bounds, rect);

  DPSgsave(ctxt);

  switch (tab_type) {
    case NSTopTabsBezelBorder:
      rect.size.height -= 16;
      NSDrawButton(rect, rect);
      borderThickness = 2;
      break;
    case NSBottomTabsBezelBorder:
      rect.size.height -= 16;
      rect.origin.y += 16;
      NSDrawButton(rect, rect);
      rect.origin.y -= 16;
      borderThickness = 2;
      break;
    case NSNoTabsBezelBorder:
      NSDrawButton(rect, rect);
      borderThickness = 2;
      break;
    case NSNoTabsLineBorder:
      [[NSColor controlDarkShadowColor] set];
      NSFrameRect(rect);
      borderThickness = 1;
      break;
    case NSNoTabsNoBorder:
      borderThickness = 0;
      break;
  }

  if (!tab_selected)
    [self selectFirstTabViewItem:nil];

  if (tab_type == NSNoTabsBezelBorder || tab_type == NSNoTabsLineBorder)
    {
      DPSgrestore(ctxt);
      return;
    }

  if (tab_type == NSBottomTabsBezelBorder)
    {
      for (i=0;i<howMany;i++) {
        // where da tab be at?
        NSSize s;
        NSRect r;
        NSPoint iP;
        NSTabViewItem *anItem = [tab_items objectAtIndex:i];
        NSTabState itemState;

        itemState = [anItem tabState];

        s = [anItem sizeOfLabel:NO];

        if (i == 0) {

          iP.x = rect.origin.x;
          iP.y = rect.origin.y;

          if (itemState == NSSelectedTab) {
	    iP.y += 1;
            [[NSImage imageNamed:@"common_TabDownSelectedLeft.tiff"]
	      compositeToPoint:iP operation: NSCompositeSourceOver];
          }
          else if (itemState == NSBackgroundTab)
            [[NSImage imageNamed:@"common_TabDownUnSelectedLeft.tiff"]
	      compositeToPoint:iP operation: NSCompositeSourceOver];
          else
	    NSLog(@"Not finished yet. Luff ya.\n");

          r.origin.x = rect.origin.x + 13;
          r.origin.y = rect.origin.y + 2;
          r.size.width = s.width;
          r.size.height = 15;

          DPSsetlinewidth(ctxt,1);
          DPSsetgray(ctxt,1);
          DPSmoveto(ctxt, r.origin.x, r.origin.y-1);
          DPSrlineto(ctxt, r.size.width, 0);
          DPSstroke(ctxt);      

          [anItem drawLabel:NO inRect:r];

          previousRect = r;
          previousState = itemState;
        } else {
          iP.x = previousRect.origin.x + previousRect.size.width;
          iP.y = rect.origin.y;

          if (itemState == NSSelectedTab) {
	    iP.y += 1;
            [[NSImage
imageNamed:@"common_TabDownUnSelectedToSelectedJunction.tiff"]
    	      compositeToPoint:iP operation: NSCompositeSourceOver];
          }
          else if (itemState == NSBackgroundTab) {
	    if (previousState == NSSelectedTab) {
	      iP.y += 1;
              [[NSImage
imageNamed:@"common_TabDownSelectedToUnSelectedJunction.tiff"]
	        compositeToPoint:iP operation: NSCompositeSourceOver];
	      iP.y -= 1;
	    } else {
              [[NSImage
imageNamed:@"common_TabDownUnSelectedJunction.tiff"]
	        compositeToPoint:iP operation: NSCompositeSourceOver];
            }
        } 
        else
	  NSLog(@"Not finished yet. Luff ya.\n");

        r.origin.x = iP.x + 13;
        r.origin.y = rect.origin.y + 2;
        r.size.width = s.width;
        r.size.height = 15;

        DPSsetlinewidth(ctxt,1);
        DPSsetgray(ctxt,1);
        DPSmoveto(ctxt, r.origin.x, r.origin.y - 1);
        DPSrlineto(ctxt, r.size.width, 0);
        DPSstroke(ctxt);      

        [anItem drawLabel:NO inRect:r];

        previousRect = r;
        previousState = itemState;
      }  

      if (i == howMany-1) {
        iP.x += s.width + 13;

        if ([anItem tabState] == NSSelectedTab)
          [[NSImage imageNamed:@"common_TabDownSelectedRight.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
        else if ([anItem tabState] == NSBackgroundTab)
          [[NSImage imageNamed:@"common_TabDownUnSelectedRight.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
        else
	  NSLog(@"Not finished yet. Luff ya.\n");
      }
    }
    return;
  }

  for (i=0;i<howMany;i++) {
    // where da tab be at?
    NSSize s;
    NSRect r;
    NSPoint iP;
    NSTabViewItem *anItem = [tab_items objectAtIndex:i];
    NSTabState itemState;

    itemState = [anItem tabState];

    s = [anItem sizeOfLabel:NO];

    if (i == 0) {

      iP.x = rect.origin.x;
      iP.y = rect.size.height;

      if (itemState == NSSelectedTab) {
	iP.y -= 1;
        [[NSImage imageNamed:@"common_TabSelectedLeft.tiff"]
	  compositeToPoint:iP operation: NSCompositeSourceOver];
      }
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

  point = [self convertPoint:point fromView:nil];

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

  if (anItem && ![anItem isEqual:tab_selected])
    {
      [self selectTabViewItem:anItem];
    }

  [self setNeedsDisplay:YES];

  return [super hitTest:aPoint];
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
