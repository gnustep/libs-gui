/** <title>NSTabView</title>

   <abstract>The tabular view class</abstract>

   Copyright (C) 1999,2000 Free Software Foundation, Inc.

   Author: Michael Hanni <mhanni@sprintmail.com>
   Date: 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "AppKit/NSColor.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSForm.h"
#include "AppKit/NSMatrix.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSTabView.h"
#include "AppKit/NSTabViewItem.h"
#include "AppKit/PSOperators.h"
#include "GNUstepGUI/GSDrawFunctions.h"

@implementation NSTabView

- (id) initWithFrame: (NSRect)rect
{
  [super initWithFrame: rect];

  // setup variables  

  ASSIGN (_items, [NSMutableArray array]);
  ASSIGN (_font, [NSFont systemFontOfSize: 0]);
  _selected = nil;

  return self;
}

- (void) dealloc
{
  RELEASE(_items);
  RELEASE(_font);
  [super dealloc];
}

// tab management.

- (void) addTabViewItem: (NSTabViewItem*)tabViewItem
{
  [self insertTabViewItem: tabViewItem atIndex: [_items count]];
}

- (void) insertTabViewItem: (NSTabViewItem*)tabViewItem
		   atIndex: (int)index
{
  [tabViewItem _setTabView: self];
  [_items insertObject: tabViewItem atIndex: index];

  if ([_delegate respondsToSelector: 
    @selector(tabViewDidChangeNumberOfTabViewItems:)])
    {
      [_delegate tabViewDidChangeNumberOfTabViewItems: self];
    }

  /* TODO (Optimize) - just mark the tabs rect as needing redisplay */
  [self setNeedsDisplay: YES];
}

- (void) removeTabViewItem: (NSTabViewItem*)tabViewItem
{
  unsigned i = [_items indexOfObject: tabViewItem];
  
  if (i == NSNotFound)
    return;

  if ([tabViewItem isEqual: _selected])
    {
      [[_selected view] removeFromSuperview];
      _selected = nil;
    }

  [_items removeObjectAtIndex: i];

  if ([_delegate respondsToSelector: 
    @selector(tabViewDidChangeNumberOfTabViewItems:)])
    {
      [_delegate tabViewDidChangeNumberOfTabViewItems: self];
    }

  /* TODO (Optimize) - just mark the tabs rect as needing redisplay unless
                       removed tab was selected */
  [self setNeedsDisplay: YES];
}

- (int) indexOfTabViewItem: (NSTabViewItem*)tabViewItem
{
  return [_items indexOfObject: tabViewItem];
}

- (int) indexOfTabViewItemWithIdentifier: (id)identifier
{
  unsigned	howMany = [_items count];
  unsigned	i;

  for (i = 0; i < howMany; i++)
    {
      id anItem = [_items objectAtIndex: i];

      if ([[anItem identifier] isEqual: identifier])
        return i;
    }

  return NSNotFound;
}

- (int) numberOfTabViewItems
{
  return [_items count];
}

- (NSTabViewItem*) tabViewItemAtIndex: (int)index
{
  return [_items objectAtIndex: index];
}

- (NSArray*) tabViewItems
{
  return (NSArray*)_items;
}

- (void) selectFirstTabViewItem: (id)sender
{
  [self selectTabViewItemAtIndex: 0];
}

- (void) selectLastTabViewItem: (id)sender
{
  [self selectTabViewItem: [_items lastObject]];
}

- (void) selectNextTabViewItem: (id)sender
{
  if ((unsigned)(_selected_item + 1) < [_items count])
    [self selectTabViewItemAtIndex: _selected_item+1];
}

- (void) selectPreviousTabViewItem: (id)sender
{
  if (_selected_item > 0)
    [self selectTabViewItemAtIndex: _selected_item-1];
}

- (NSTabViewItem*) selectedTabViewItem
{
  if (_selected_item == NSNotFound || [_items count] == 0)
    return nil;
  return [_items objectAtIndex: _selected_item];
}

- (void) selectTabViewItem: (NSTabViewItem*)tabViewItem
{
  BOOL canSelect = YES;

  if ([_delegate respondsToSelector: 
    @selector(tabView: shouldSelectTabViewItem:)])
    {
      canSelect = [_delegate tabView: self
		shouldSelectTabViewItem: tabViewItem];
    }

  if (canSelect)
    {
      NSView *selectedView;

      if (_selected != nil)
        {
          [_selected _setTabState: NSBackgroundTab];

	  /* NB: If [_selected view] is nil this does nothing, which
             is fine.  */
	  [[_selected view] removeFromSuperview];
	}

      _selected = tabViewItem;

      if ([_delegate respondsToSelector: 
	@selector(tabView: willSelectTabViewItem:)])
	{
	  [_delegate tabView: self willSelectTabViewItem: _selected];
	}

      _selected_item = [_items indexOfObject: _selected];
      [_selected _setTabState: NSSelectedTab];

      selectedView = [_selected view];

      if (selectedView != nil)
	{
	  [self addSubview: selectedView];
	  [selectedView setFrame: [self contentRect]];
	  [_window makeFirstResponder: [_selected initialFirstResponder]];
	}
      
      /* Will need to redraw tabs and content area. */
      [self setNeedsDisplay: YES];
      
      if ([_delegate respondsToSelector: 
	@selector(tabView: didSelectTabViewItem:)])
	{
	  [_delegate tabView: self didSelectTabViewItem: _selected];
	}
    }
}

- (void) selectTabViewItemAtIndex: (int)index
{
  if (index < 0 || index >= [_items count])
    [self selectTabViewItem: nil];
  else
    [self selectTabViewItem: [_items objectAtIndex: index]];
}

- (void) selectTabViewItemWithIdentifier:(id)identifier 
{
  int index = [self indexOfTabViewItemWithIdentifier: identifier];
  [self selectTabViewItemAtIndex: index];
}

- (void) takeSelectedTabViewItemFromSender: (id)sender
{
  int	index = -1;

  if ([sender respondsToSelector: @selector(indexOfSelectedItem)] == YES)
    {
      index = [sender indexOfSelectedItem];
    }
  else if ([sender isKindOfClass: [NSMatrix class]] == YES)
    {
      int	cols = [sender numberOfColumns];
      int	row = [sender selectedRow];
      int	col = [sender selectedColumn];

      if (row >= 0 && col >= 0)
	{
	  index = row * cols + col;
	}
    }
  [self selectTabViewItemAtIndex: index];
}

- (void) setFont: (NSFont*)font
{
  ASSIGN(_font, font);
}

- (NSFont*) font
{
  return _font;
}

- (void) setTabViewType: (NSTabViewType)tabViewType
{
  _type = tabViewType;
}

- (NSTabViewType) tabViewType
{
  return _type;
}

- (void) setDrawsBackground: (BOOL)flag
{
  _draws_background = flag;
}

- (BOOL) drawsBackground
{
  return _draws_background;
}

- (void) setAllowsTruncatedLabels: (BOOL)allowTruncatedLabels
{
  _truncated_label = allowTruncatedLabels;
}

- (BOOL) allowsTruncatedLabels
{
  return _truncated_label;
}

- (void) setDelegate: (id)anObject
{
  _delegate = anObject;
}

- (id) delegate
{
  return _delegate;
}

// content and size

- (NSSize) minimumSize
{
  switch (_type)
    {
      case NSTopTabsBezelBorder:
	return NSMakeSize(2, 19.5);
      case NSNoTabsBezelBorder:
	return NSMakeSize(2, 3);
      case NSBottomTabsBezelBorder:
	return NSMakeSize(2, 16);
      default:
	return NSZeroSize;
    }
}

- (NSRect) contentRect
{
  NSRect cRect = _bounds;

  if (_type == NSTopTabsBezelBorder)
    {
      cRect.origin.y += 1; 
      cRect.origin.x += 0.5; 
      cRect.size.width -= 2;
      cRect.size.height -= 18.5;
    }
  
  if (_type == NSNoTabsBezelBorder)
    {
      cRect.origin.y += 1; 
      cRect.origin.x += 0.5; 
      cRect.size.width -= 2;
      cRect.size.height -= 2;
    }

  if (_type == NSBottomTabsBezelBorder)
    {
      cRect.size.height -= 8;
      cRect.origin.y = 8;
    }

  return cRect;
}

// Drawing.

- (void) drawRect: (NSRect)rect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  int			howMany = [_items count];
  int			i;
  NSRect		previousRect = NSMakeRect(0, 0, 0, 0);
  int			previousState = 0;
  NSRect		aRect = _bounds;

  DPSgsave(ctxt);

  switch (_type)
    {
      default:
      case NSTopTabsBezelBorder: 
	aRect.size.height -= 16;
	[GSDrawFunctions drawButton: aRect : NSZeroRect];
	break;

      case NSBottomTabsBezelBorder: 
	aRect.size.height -= 16;
	aRect.origin.y += 16;
	[GSDrawFunctions drawButton: aRect : rect];
	aRect.origin.y -= 16;
	break;

      case NSNoTabsBezelBorder: 
	[GSDrawFunctions drawButton: aRect : rect];
	break;

      case NSNoTabsLineBorder: 
	[[NSColor controlDarkShadowColor] set];
	NSFrameRect(aRect);
	break;

      case NSNoTabsNoBorder: 
	break;
    }

  if (!_selected && howMany > 0)
    [self selectFirstTabViewItem: nil];

  if (_type == NSNoTabsBezelBorder || _type == NSNoTabsLineBorder)
    {
      DPSgrestore(ctxt);
      return;
    }

  if (_type == NSBottomTabsBezelBorder)
    {
      for (i = 0; i < howMany; i++) 
	{
	  // where da tab be at?
	  NSSize	s;
	  NSRect	r;
	  NSPoint	iP;
	  NSTabViewItem *anItem = [_items objectAtIndex: i];
	  NSTabState	itemState;

	  itemState = [anItem tabState];

	  s = [anItem sizeOfLabel: NO];

	  if (i == 0)
	    {
	      int iFlex = 0;
	      iP.x = aRect.origin.x;
	      iP.y = aRect.origin.y;
	      
	      [[NSColor controlBackgroundColor] set];

	      if (itemState == NSSelectedTab)
		{
		  iP.y += 1;
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabDownSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		  iFlex = 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
		  iP.y += 1;
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabDownUnSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		}
	      else
		NSLog(@"Not finished yet. Luff ya.\n");

	      r.origin.x = aRect.origin.x + 13;
	      r.origin.y = aRect.origin.y + 2;
	      r.size.width = s.width;
	      r.size.height = 15 + iFlex;

	      DPSsetlinewidth(ctxt,1);
	      DPSsetgray(ctxt, NSWhite);
	      DPSmoveto(ctxt, r.origin.x, r.origin.y-1);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      

	      [anItem drawLabel: NO inRect: r];

	      previousRect = r;
	      previousState = itemState;
	    }
	  else
	    {
	      int	iFlex = 0;

	      iP.x = previousRect.origin.x + previousRect.size.width;
	      iP.y = aRect.origin.y;
	      
	      [[NSColor controlBackgroundColor] set];

	      if (itemState == NSSelectedTab) 
		{
		  iP.y += 1;
		  iFlex = 1;
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed:
		    @"common_TabDownUnSelectedToSelectedJunction.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
		  if (previousState == NSSelectedTab)
		    {
		      iP.y += 1;
	              NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		      [[NSImage imageNamed:
			@"common_TabDownSelectedToUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      iP.y -= 1;
		      iFlex = -1;
		    }
		  else
		    {
		      //		    iP.y += 1;
	              NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		      [[NSImage imageNamed:
			@"common_TabDownUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      //iP.y -= 1;
		      iFlex = -1;
		    }
		} 
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	      
	      r.origin.x = iP.x + 13;
	      r.origin.y = aRect.origin.y + 2;
	      r.size.width = s.width;
	      r.size.height = 15 + iFlex; // was 15

	      iFlex = 0;

	      DPSsetlinewidth(ctxt,1);
	      DPSsetgray(ctxt, NSWhite);
	      DPSmoveto(ctxt, r.origin.x, r.origin.y - 1);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      

	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }  

	  if (i == howMany-1)
	    {
	      iP.x += s.width + 13;

	      [[NSColor controlBackgroundColor] set];

	      if ([anItem tabState] == NSSelectedTab)
	        {
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabDownSelectedRight.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
	        }
	      else if ([anItem tabState] == NSBackgroundTab)
		{
		  //		  iP.y += 1;
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabDownUnSelectedRight.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  //		  iP.y -= 1;
		}
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }
	}
    }
  else if (_type == NSTopTabsBezelBorder)
    {
      for (i = 0; i < howMany; i++) 
	{
	  // where da tab be at?
	  NSSize s;
	  NSRect r;
	  NSPoint iP;
	  NSTabViewItem *anItem = [_items objectAtIndex: i];
	  NSTabState itemState;
	  
	  itemState = [anItem tabState];
	  
	  s = [anItem sizeOfLabel: NO];
	  
	  if (i == 0)
	    {
	      iP.x = aRect.origin.x;
	      iP.y = aRect.size.height;

	      [[NSColor controlBackgroundColor] set];
	      
	      if (itemState == NSSelectedTab)
		{
		  iP.y -= 1;
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else if (itemState == NSBackgroundTab)
	        {
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabUnSelectedLeft.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
	        }
	      else
		NSLog(@"Not finished yet. Luff ya.\n");

	      r.origin.x = aRect.origin.x + 13;
	      r.origin.y = aRect.size.height;
	      r.size.width = s.width;
	      r.size.height = 15;
	      
	      DPSsetlinewidth(ctxt,1);
	      DPSsetgray(ctxt, NSWhite);
	      DPSmoveto(ctxt, r.origin.x, r.origin.y+16);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      
	      
	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }
	  else
	    {
	      iP.x = previousRect.origin.x + previousRect.size.width;
	      iP.y = aRect.size.height;
	      
	      [[NSColor controlBackgroundColor] set];

	      if (itemState == NSSelectedTab)
		{
		  iP.y -= 1;
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed:
		    @"common_TabUnSelectToSelectedJunction.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else if (itemState == NSBackgroundTab)
		{
		  if (previousState == NSSelectedTab)
		    {
		      iP.y -= 1;
	              NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		      [[NSImage imageNamed:
			@"common_TabSelectedToUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      iP.y += 1;
		    }
		  else
		    {
	              NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		      [[NSImage imageNamed:
			@"common_TabUnSelectedJunction.tiff"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		    }
		} 
	      else
		NSLog(@"Not finished yet. Luff ya.\n");

	      r.origin.x = iP.x + 13;
	      r.origin.y = aRect.size.height;
	      r.size.width = s.width;
	      r.size.height = 15;

	      DPSsetlinewidth(ctxt,1);
	      DPSsetgray(ctxt, NSWhite);
	      DPSmoveto(ctxt, r.origin.x, r.origin.y+16);
	      DPSrlineto(ctxt, r.size.width, 0);
	      DPSstroke(ctxt);      
	      
	      [anItem drawLabel: NO inRect: r];
	      
	      previousRect = r;
	      previousState = itemState;
	    }  

	  if (i == howMany-1)
	    {
	      iP.x += s.width + 13;
	      
	      [[NSColor controlBackgroundColor] set];
	    
	      if ([anItem tabState] == NSSelectedTab)
	        {	      
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabSelectedRight.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}  
	      else if ([anItem tabState] == NSBackgroundTab)
		{
	          NSRectFill (NSMakeRect (iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabUnSelectedRight.tiff"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }
	}
    }

  DPSgrestore(ctxt);
}

- (BOOL) isOpaque
{
  return NO;
}

// Event handling.

- (NSTabViewItem*) tabViewItemAtPoint: (NSPoint)point
{
  int		howMany = [_items count];
  int		i;

  point = [self convertPoint: point fromView: nil];

  for (i = 0; i < howMany; i++)
    {
      NSTabViewItem *anItem = [_items objectAtIndex: i];

      if (NSPointInRect(point,[anItem _tabRect]))
	return anItem;
    }

  return nil;
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  NSTabViewItem *anItem = [self tabViewItemAtPoint: location];
  
  if (anItem != nil  &&  ![anItem isEqual: _selected])
    {
      [self selectTabViewItem: anItem];
    }
}


- (NSControlSize) controlSize
{
  // FIXME
  return NSRegularControlSize;
}

/**
 * Not implemented.
 */
- (void) setControlSize: (NSControlSize)controlSize
{
  // FIXME 
}

- (NSControlTint) controlTint
{
  // FIXME
  return NSDefaultControlTint;
}

/**
 * Not implemented.
 */
- (void) setControlTint: (NSControlTint)controlTint
{
  // FIXME 
}

// Coding.

- (void) encodeWithCoder: (NSCoder*)aCoder
{ 
  [super encodeWithCoder: aCoder];
           
  [aCoder encodeObject: _items];
  [aCoder encodeObject: _font];
  [aCoder encodeValueOfObjCType: @encode(NSTabViewType) at: &_type];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_draws_background];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_truncated_label];
  [aCoder encodeConditionalObject: _delegate];
  [aCoder encodeValueOfObjCType: "i" at: &_selected_item];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      if ([aDecoder containsValueForKey: @"NSAllowTruncatedLabels"])
        {
	  [self setAllowsTruncatedLabels: [aDecoder decodeBoolForKey: 
							@"NSAllowTruncatedLabels"]];
	}
      if ([aDecoder containsValueForKey: @"NSDrawsBackground"])
        {
	  [self setDrawsBackground: [aDecoder decodeBoolForKey: 
						  @"NSDrawsBackground"]];
	}
      if ([aDecoder containsValueForKey: @"NSFont"])
        {
	  [self setFont: [aDecoder decodeObjectForKey: @"NSFont"]];
	}
      if ([aDecoder containsValueForKey: @"NSTabViewItems"])
        {
	  NSArray *items = [aDecoder decodeObjectForKey: @"NSTabViewItems"];
	  NSEnumerator *enumerator = [items objectEnumerator];
	  NSTabViewItem *item;
	  
	  while ((item = [enumerator nextObject]) != nil)
	    {
	      [self addTabViewItem: item];
	    }
	}
      if ([aDecoder containsValueForKey: @"NSSelectedTabViewItem"])
        {
	  [self selectTabViewItem: [aDecoder decodeObjectForKey: 
						 @"NSSelectedTabViewItem"]];
	}
      if ([aDecoder containsValueForKey: @"NSTvFlags"])
        {
	    //int flags = [aDecoder decodeObjectForKey: @"NSTvFlags"]];
	}
    }
  else
    {
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_items];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_font];
      [aDecoder decodeValueOfObjCType: @encode(NSTabViewType) at: &_type];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_draws_background];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_truncated_label];
      _delegate = [aDecoder decodeObject];
      [aDecoder decodeValueOfObjCType: "i" at: &_selected_item];
      _selected = [_items objectAtIndex: _selected_item];
    }
  return self;
}
@end
