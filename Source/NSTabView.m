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
#include "GNUstepGUI/GSTheme.h"

@implementation NSTabView

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSTabView class])
    {
      [self setVersion: 2];
    }
}

- (id) initWithFrame: (NSRect)rect
{
  self = [super initWithFrame: rect];

  if (self)
    {
      // setup variables  
      ASSIGN(_items, [NSMutableArray array]);
      ASSIGN(_font, [NSFont systemFontOfSize: 0]);
      _selected_item = NSNotFound;
      //_selected = nil;
      //_truncated_label = NO;
    }

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

  if ((_selected_item != NSNotFound) && (index <= _selected_item))
    {
      _selected_item++;
    }

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
      // We cannot call [self selectTabViewItem: nil] here as the delegate might refuse this
      [[_selected view] removeFromSuperview];
      _selected = nil;
      _selected_item = NSNotFound;
    }

  [_items removeObjectAtIndex: i];

  if ((_selected_item != NSNotFound) && (i <= _selected_item))
    {
      _selected_item--;
    }

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
  if ((_selected_item != NSNotFound) && ((unsigned)(_selected_item + 1) < [_items count]))
    {
      [self selectTabViewItemAtIndex: _selected_item + 1];
    }
}

- (void) selectPreviousTabViewItem: (id)sender
{
  if ((_selected_item != NSNotFound) && (_selected_item > 0))
    {
      [self selectTabViewItemAtIndex: _selected_item - 1];
    }
}

- (NSTabViewItem*) selectedTabViewItem
{
  // FIXME: Why not just return _selected?
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

      if ([_delegate respondsToSelector: 
	@selector(tabView: willSelectTabViewItem:)])
	{
	  [_delegate tabView: self willSelectTabViewItem: tabViewItem];
	}

      _selected = tabViewItem;
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

- (void) selectTabViewItemWithIdentifier: (id)identifier 
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
  // FIXME: This should allow some space for the tabs
  switch (_type)
    {
      case NSTopTabsBezelBorder:
	return NSMakeSize(2, 19.5);
      case NSNoTabsBezelBorder:
	return NSMakeSize(2, 3);
      case NSNoTabsLineBorder:
	return NSMakeSize(2, 3);
      case NSBottomTabsBezelBorder:
	return NSMakeSize(2, 16);
      case NSLeftTabsBezelBorder:
	return NSMakeSize(16, 3);
      case NSRightTabsBezelBorder:
	return NSMakeSize(16, 3);
      case NSNoTabsNoBorder:
      default:
	return NSZeroSize;
    }
}

- (NSRect) contentRect
{
  NSRect cRect = _bounds;

  /* 
     FIXME: All these numbers seem wrong to me.
     For a bezel border we loose 2 pixel on each side, 
     for a line border 1 pixel. On top of that we will 
     need the space for the tab.
  */
  switch (_type)
    {
      case NSTopTabsBezelBorder:
	cRect.origin.y += 1; 
	cRect.origin.x += 0.5; 
	cRect.size.width -= 2;
	cRect.size.height -= 18.5;
	break;
      case NSNoTabsBezelBorder:
	cRect.origin.y += 1; 
	cRect.origin.x += 0.5; 
	cRect.size.width -= 2;
	cRect.size.height -= 2;
	break;
      case NSNoTabsLineBorder:
	cRect.origin.y += 1; 
	cRect.origin.x += 0.5; 
	cRect.size.width -= 2;
	cRect.size.height -= 2;
	break;
      case NSBottomTabsBezelBorder:
	cRect.size.height -= 8;
	cRect.origin.y = 8;
	break;
      case NSLeftTabsBezelBorder:
	cRect.size.width -= 16;
	cRect.origin.x += 16;
	break;
      case NSRightTabsBezelBorder:
	cRect.size.width -= 16;
	break;
      case NSNoTabsNoBorder:
      default:
	break;
    }

  return cRect;
}

// Drawing.

- (void) drawRect: (NSRect)rect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
  GSTheme		*theme = [GSTheme theme];
  int			howMany = [_items count];
  int			i;
  int			previousState = 0;
  NSRect		aRect = _bounds;
  NSColor *lineColour = [NSColor highlightColor];
  NSColor *backgroundColour = [[self window] backgroundColor];
  BOOL truncate = [self allowsTruncatedLabels];

  // Make sure some tab is selected
  if (!_selected && howMany > 0)
    [self selectFirstTabViewItem: nil];

  DPSgsave(ctxt);

  switch (_type)
    {
      default:
      case NSTopTabsBezelBorder: 
	aRect.size.height -= 16;
	[theme drawButton: aRect withClip: rect];
	break;

      case NSBottomTabsBezelBorder: 
	aRect.size.height -= 16;
	aRect.origin.y += 16;
	[theme drawButton: aRect withClip: rect];
	aRect.origin.y -= 16;
	break;

      case NSLeftTabsBezelBorder: 
	aRect.size.width -= 18;
	aRect.origin.x += 18;
	[theme drawButton: aRect withClip: rect];
	break;

      case NSRightTabsBezelBorder: 
	aRect.size.width -= 18;
	[theme drawButton: aRect withClip: rect];
	break;

      case NSNoTabsBezelBorder: 
	[theme drawButton: aRect withClip: rect];
	break;

      case NSNoTabsLineBorder: 
	[[NSColor controlDarkShadowColor] set];
	NSFrameRect(aRect);
	break;

      case NSNoTabsNoBorder: 
	break;
    }

  if (_type == NSBottomTabsBezelBorder)
    {
      NSPoint iP;

      iP.x = _bounds.origin.x;
      iP.y = _bounds.origin.y;
	      
      for (i = 0; i < howMany; i++) 
	{
	  NSRect r;
	  NSRect fRect;
	  NSTabViewItem *anItem = [_items objectAtIndex: i];
	  NSTabState itemState = [anItem tabState];
	  NSSize s = [anItem sizeOfLabel: truncate];
	  
	  [backgroundColour set];

	  if (i == 0)
	    {
	      if (itemState == NSSelectedTab)
		{
		  iP.y += 1;
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabDownSelectedLeft"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabDownUnSelectedLeft"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }
	  else
	    {
	      if (itemState == NSSelectedTab) 
		{
		  iP.y += 1;
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed:
		    @"common_TabDownUnSelectedToSelectedJunction"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
		  if (previousState == NSSelectedTab)
		    {
		      iP.y += 1;
	              NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		      [[NSImage imageNamed:
			@"common_TabDownSelectedToUnSelectedJunction"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      iP.y -= 1;
		    }
		  else
		    {
	              NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		      [[NSImage imageNamed:
			@"common_TabDownUnSelectedJunction"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		    }
		} 
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }  

	  r.origin.x = iP.x + 13;
	  r.origin.y = iP.y + 2;
	  r.size.width = s.width;
	  r.size.height = 15;

	  fRect = r;
	  if (itemState == NSSelectedTab)
	    {
	      // Undraw the line that separates the tab from its view.
	      fRect.origin.y += 1;
	      fRect.size.height += 1;
	    }
	  NSRectFill(fRect);

	  // Draw the line at the bottom of the item
	  [lineColour set];
	  DPSsetlinewidth(ctxt, 1);
	  DPSmoveto(ctxt, r.origin.x, r.origin.y - 1);
	  DPSrlineto(ctxt, r.size.width, 0);
	  DPSstroke(ctxt);
	  
	  // Label
	  [anItem drawLabel: truncate inRect: r];
	  
	  iP.x += s.width + 13;
	  previousState = itemState;

	  if (i == howMany - 1)
	    {
	      [backgroundColour set];

	      if ([anItem tabState] == NSSelectedTab)
	        {
		  iP.y += 1;
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabDownSelectedRight"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y -= 1;
	        }
	      else if ([anItem tabState] == NSBackgroundTab)
		{
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabDownUnSelectedRight"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }
	}
    }
  else if (_type == NSTopTabsBezelBorder)
    {
      NSPoint iP;

      iP.x = _bounds.origin.x;
      // FIXNE: Why not NSMaxY(_bounds)?
      iP.y = _bounds.size.height - 16;

      for (i = 0; i < howMany; i++) 
	{
	  NSRect r;
	  NSRect fRect;
	  NSTabViewItem *anItem = [_items objectAtIndex: i];
	  NSTabState itemState = [anItem tabState];
	  NSSize s = [anItem sizeOfLabel: truncate];

	  [backgroundColour set];
	  
	  if (i == 0)
	    {
	      if (itemState == NSSelectedTab)
		{
		  iP.y -= 1;
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabSelectedLeft"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y += 1;
		}
	      else if (itemState == NSBackgroundTab)
	        {
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabUnSelectedLeft"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
	        }
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }
	  else
	    {
	      if (itemState == NSSelectedTab)
		{
		  iP.y -= 1;
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed:
		    @"common_TabUnSelectToSelectedJunction"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y += 1;
		}
	      else if (itemState == NSBackgroundTab)
		{
		  if (previousState == NSSelectedTab)
		    {
		      iP.y -= 1;
	              NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		      [[NSImage imageNamed:
			@"common_TabSelectedToUnSelectedJunction"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		      iP.y += 1;
		    }
		  else
		    {
	              NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		      [[NSImage imageNamed:
			@"common_TabUnSelectedJunction"]
			compositeToPoint: iP operation: NSCompositeSourceOver];
		    }
		} 
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }  

	  r.origin.x = iP.x + 13;
	  r.origin.y = iP.y;
	  r.size.width = s.width;
	  r.size.height = 15;
	  
	  fRect = r;
	  if (itemState == NSSelectedTab)
	    {
	      // Undraw the line that separates the tab from its view.
	      fRect.origin.y -= 1;
	      fRect.size.height += 1;
	    }
	  NSRectFill(fRect);

	  // Draw the line at the top of the item
	  [lineColour set];
	  DPSsetlinewidth(ctxt, 1);
	  DPSmoveto(ctxt, r.origin.x, r.origin.y + 16);
	  DPSrlineto(ctxt, r.size.width, 0);
	  DPSstroke(ctxt);
	  
	  // Label
	  [anItem drawLabel: truncate inRect: r];
	  
	  iP.x += s.width + 13;
	  previousState = itemState;

	  if (i == howMany - 1)
	    {
	      [backgroundColour set];
	    
	      if ([anItem tabState] == NSSelectedTab)
	        {	      
		  iP.y -= 1;
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabSelectedRight"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		  iP.y += 1;
		}  
	      else if ([anItem tabState] == NSBackgroundTab)
		{
	          NSRectFill(NSMakeRect(iP.x, iP.y, 14, 17));
		  [[NSImage imageNamed: @"common_TabUnSelectedRight"]
		    compositeToPoint: iP operation: NSCompositeSourceOver];
		}
	      else
		NSLog(@"Not finished yet. Luff ya.\n");
	    }
	}
    }
  // FIXME: Missing drawing code for other cases

  DPSgrestore(ctxt);
}

- (BOOL) isOpaque
{
  return NO;
}

// Event handling.

/* 
 *  Find the tab view item containing the NSPoint point. This point 
 *  is expected to be alreay in the coordinate system of the tab view.
 */
- (NSTabViewItem*) tabViewItemAtPoint: (NSPoint)point
{
  int howMany = [_items count];
  int i;

  for (i = 0; i < howMany; i++)
    {
      NSTabViewItem *anItem = [_items objectAtIndex: i];

      if (NSPointInRect(point, [anItem _tabRect]))
	return anItem;
    }

  return nil;
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [self convertPoint: [theEvent locationInWindow] 
			   fromView: nil];
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
  if ([aCoder allowsKeyedCoding])
    {
      unsigned int type = _type; // no flags set...

      [aCoder encodeBool: [self allowsTruncatedLabels] forKey: @"NSAllowTruncatedLabels"];
      [aCoder encodeBool: [self drawsBackground] forKey: @"NSDrawsBackground"];
      [aCoder encodeObject: [self font] forKey: @"NSFont"];
      [aCoder encodeObject: _items forKey: @"NSTabViewItems"];
      [aCoder encodeObject: [self selectedTabViewItem] forKey: @"NSSelectedTabViewItem"];
      [aCoder encodeInt: type forKey: @"NSTvFlags"];
    }
  else
    {
      [aCoder encodeObject: _items];
      [aCoder encodeObject: _font];
      [aCoder encodeValueOfObjCType: @encode(NSTabViewType) at: &_type];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_draws_background];
      [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_truncated_label];
      [aCoder encodeConditionalObject: _delegate];
      [aCoder encodeValueOfObjCType: "i" at: &_selected_item];
    }
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
	  ASSIGN(_items, [aDecoder decodeObjectForKey: @"NSTabViewItems"]);
	}
      if ([aDecoder containsValueForKey: @"NSSelectedTabViewItem"])
        {
	  [self selectTabViewItem: [aDecoder decodeObjectForKey: 
						 @"NSSelectedTabViewItem"]];
	}
      if ([aDecoder containsValueForKey: @"NSTvFlags"])
        {
	  int vFlags = [aDecoder decodeIntForKey: @"NSTvFlags"];

	  [self setControlTint: ((vFlags & 0x70000000) >> 28)];
	  [self setControlSize: ((vFlags & 0x0c000000) >> 26)];
	  [self setTabViewType: (vFlags & 0x00000007)];
	}
    }
  else
    {
      int version = [aDecoder versionForClassName: @"NSTabView"];

      [aDecoder decodeValueOfObjCType: @encode(id) at: &_items];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_font];
      [aDecoder decodeValueOfObjCType: @encode(NSTabViewType) at: &_type];
      if (version < 2)
        {
	  switch(_type)
	    {
	      case 0:
		_type = NSTopTabsBezelBorder;
		break;
	      case 5:
		_type = NSLeftTabsBezelBorder;
		break;
	      case 1:
		_type = NSBottomTabsBezelBorder;
		break;
	      case 6:
		_type = NSRightTabsBezelBorder;
		break;
	      case 2:
		_type = NSNoTabsBezelBorder;
		break;
	      case 3:
		_type = NSNoTabsLineBorder;
		break;
	      case 4:
		_type = NSNoTabsNoBorder;
		break;
	      default:
		break;
	    }
	}
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_draws_background];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_truncated_label];
      _delegate = [aDecoder decodeObject];
      [aDecoder decodeValueOfObjCType: "i" at: &_selected_item];
      _selected = [_items objectAtIndex: _selected_item];
    }
  return self;
}
@end
