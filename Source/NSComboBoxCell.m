/*
   NSComboBoxCell.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Gerrit van Dyk <gerritvd@decillion.net>
   Date: 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#import <AppKit/AppKit.h>
#import "GSComboSupport.h"

@interface NSComboBoxCell(_Private_)
- (void)_createButtonCell;
- (void)_didClick:(id)sender;
- (NSImage *)_buttonImage;
- (GSComboWindow *)_popUp;
@end

@implementation NSComboBoxCell

- (id)initTextCell:(NSString *)aString
{
   self = [super initTextCell:aString];
   _delegate = nil;
   _dataSource = nil;
   _buttonCell = nil;
   _popUpList = [[NSMutableArray array] retain];
   _usesDataSource = NO;
   _visibleItems = 10;
   _intercellSpacing = NSMakeSize(0.0,0.0);
   _itemHeight = 14;

   _popView = nil;
   _canPop = NO;
   _popRect = NSZeroRect;
   _mUpEvent = nil;
   [self _createButtonCell];
   return self;
}

- (void)dealloc
{
   [_delegate release];
   [_dataSource release];
   [_buttonCell release];
   [_popUpList release];
   [super dealloc];
}

- (BOOL)hasVerticalScroller { return _hasVerticalScroller; }
- (void)setHasVerticalScroller:(BOOL)flag
{
   _hasVerticalScroller = flag;
}

- (NSSize)intercellSpacing { return _intercellSpacing; }
- (void)setIntercellSpacing:(NSSize)aSize
{
   _intercellSpacing = aSize;
}

- (float)itemHeight { return _itemHeight; }
- (void)setItemHeight:(float)itemHeight
{
   if (itemHeight > 14)
      _itemHeight = itemHeight;
}

- (int)numberOfVisibleItems { return _visibleItems; }
- (void)setNumberOfVisibleItems:(int)visibleItems
{
   if (_visibleItems > 10)
      _visibleItems = visibleItems;
}

- (void)reloadData
{
}

- (void)noteNumberOfItemsChanged
{
}

- (BOOL)usesDataSource { return _usesDataSource; }
- (void)setUsesDataSource:(BOOL)flag
{
   _usesDataSource = flag;
}

- (void)scrollItemAtIndexToTop:(int)index
{
}

- (void)scrollItemAtIndexToVisible:(int)index
{
}

- (void)selectItemAtIndex:(int)index
{
}

- (void)deselectItemAtIndex:(int)index
{
}

- (int)indexOfSelectedItem
{
   return 0;
}

- (int)numberOfItems
{
   SEL	selector;

   if (_usesDataSource)
   {
      if (!_dataSource)
	 NSLog(@"No DataSource Specified");
      else
      {
	 if ([[self controlView] isKindOfClass:[NSComboBox class]])
	 {
	    selector = @selector(numberOfItemsInComboBox:);
	    if ([_dataSource respondsToSelector:selector])
	       return [_dataSource numberOfItemsInComboBox:
				      (NSComboBox *)[self controlView]];
	 }
	 else
	 {
	    selector = @selector(numberOfItemsInComboBoxCell:);
	    if ([_dataSource respondsToSelector:selector])
	       return [_dataSource numberOfItemsInComboBoxCell:self];
	 }
      }
   }
   else
      return [_popUpList count];
	 
   return 0;
}

- (id)dataSource { return _dataSource; }
- (void)setDataSource:(id)aSource
{
   if (_dataSource != aSource)
   {
      [_dataSource release];
      _dataSource = [aSource retain];
   }
}

- (void)addItemWithObjectValue:(id)object
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
   else
      [_popUpList addObject:object];
}

- (void)addItemsWithObjectValues:(NSArray *)objects
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
   else
      [_popUpList addObjectsFromArray:objects];
}

- (void)insertItemWithObjectValue:(id)object atIndex:(int)index
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
   else
      [_popUpList insertObject:object atIndex:index];
}

- (void)removeItemWithObjectValue:(id)object
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
   else
      [_popUpList removeObject:object];
}

- (void)removeItemAtIndex:(int)index
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
   else
      [_popUpList removeObjectAtIndex:index];
}

- (void)removeAllItems
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
   else
      [_popUpList removeAllObjects];
}

- (void)selectItemWithObjectValue:(id)object
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
}

- (id)itemObjectValueAtIndex:(int)index
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
   return nil;
}

- (id)objectValueOfSelectedItem
{
   if (_usesDataSource)
      NSLog(@"Method Invalid: ComboBox uses dataSource");
   return nil;
}

- (int)indexOfItemWithObjectValue:(id)object
{
   if (_usesDataSource)
   {
      NSLog(@"Method Invalid: ComboBox uses dataSource");
      return 0;
   }
   return [_popUpList indexOfObject:object];
}

- (NSArray *)_dataSourceObjectValues
{
   NSMutableArray	*array = nil;
   id			obj;
   SEL			selector;
   int			i,cnt;
   
   if (!_dataSource)
      NSLog(@"No DataSource Specified");
   else
   {
      cnt = [self numberOfItems];
      if ([[self controlView] isKindOfClass:[NSComboBox class]])
      {
	 obj = [self controlView];
	 selector = @selector(comboBox:objectValueForItemAtIndex:);
	 if ([_dataSource respondsToSelector:selector])
	 {
	    array = [NSMutableArray array];
	    for (i=0;i<cnt;i++)
	       [array addObject:[_dataSource comboBox:obj
					     objectValueForItemAtIndex:i]];
	 }
      }
      else
      {
	 obj = self;
	 selector = @selector(comboBoxCell:indexOfItemWithStringValue:);
	 if ([_dataSource respondsToSelector:selector])
	 {
	    array = [NSMutableArray array];
	    for (i=0;i<cnt;i++)
	       [array addObject:[_dataSource comboBoxCell:obj
					     objectValueForItemAtIndex:i]];
	 }
      }
   }
   return array;
}

- (NSArray *)objectValues
{
   if (_usesDataSource)
      return [self _dataSourceObjectValues];
   return _popUpList;
}

- (void)performPopUsingSelector:(SEL)aSelector
			 inRect:(NSRect)cellFrame
			 ofView:(NSView *)controlView
{
   _canPop = YES;
   _popRect = cellFrame;
   _popView = [controlView retain];
   [self performSelector:aSelector withObject:self];
   [_popView release];
   _popView = nil;
   _canPop = NO;
   _popRect = NSZeroRect;
}

#define CBButtonWidth 18
#define CBFrameWidth 2

- (NSRect)textCellFrameFromRect:(NSRect)cellRect
{
   return NSMakeRect(NSMinX(cellRect),
		     NSMinY(cellRect),
		     NSWidth(cellRect)-CBButtonWidth,
		     NSHeight(cellRect));
}

- (NSRect)buttonCellFrameFromRect:(NSRect)cellRect
{
   return NSMakeRect(NSMaxX(cellRect)-CBButtonWidth,
		     NSMinY(cellRect)+CBFrameWidth,
		     CBButtonWidth,
		     NSHeight(cellRect)-(CBFrameWidth*2.0));
}

- (void)didClick:(NSEvent *)theEvent inRect:(NSRect)cellFrame
	  ofView:(NSView *)controlView
{
   NSPoint	point;

   point = [theEvent locationInWindow];
   point = [controlView convertPoint:point fromView:nil];
   if (NSPointInRect(point,[self buttonCellFrameFromRect:cellFrame]))
   {
      [_buttonCell setCellAttribute:NSCellHighlighted to:1];
      [controlView displayRect:cellFrame];
//       [[NSDPSContext currentContext] flush];
//       [[controlView window] display];
      [self performPopUsingSelector: @selector(_didClick:)
	    inRect:cellFrame
	    ofView:controlView];
      [_buttonCell setCellAttribute:NSCellHighlighted to:0];
      [controlView displayRect:cellFrame];
//       [[NSDPSContext currentContext] flush];
//       [[controlView window] display];
   }
}

// Overridden
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
//    if ([[NSDPSContext currentContext] isDrawingToScreen])
//    {
   [super drawWithFrame:[self textCellFrameFromRect:cellFrame]
	  inView:controlView];
   [_buttonCell drawWithFrame:[self buttonCellFrameFromRect:cellFrame]
		inView:controlView];
//    }
//    else
//       [super drawWithFrame:cellFrame inView:controlView];
}

- (void)highlight:(BOOL)flag
	withFrame:(NSRect)cellFrame
	   inView:(NSView *)controlView
{
//    if ([[NSDPSContext currentContext] isDrawingToScreen])
//    {
      [super highlight:flag
	     withFrame:[self textCellFrameFromRect:cellFrame]
	     inView:controlView];
      [_buttonCell highlight:flag
		   withFrame:[self buttonCellFrameFromRect:cellFrame]
		   inView:controlView];
//    }
//    else
//       [super highlight:flag withFrame:cellFrame inView:controlView];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView
		 editor:(NSText *)textObj delegate:(id)anObject
		  start:(int)selStart length:(int)selLength
{
   [super selectWithFrame:[self textCellFrameFromRect:aRect]
	  inView:controlView
	  editor:textObj delegate:anObject
	  start:selStart length:selLength];
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView
	       editor:(NSText *)textObj delegate:(id)anObject
		event:(NSEvent *)theEvent
{
   [super editWithFrame:[self textCellFrameFromRect:aRect]
	  inView:controlView
	  editor:textObj delegate:anObject
	  event:theEvent];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame
	    ofView:(NSView *)controlView untilMouseUp:(BOOL)flag
{
   NSEvent	*nEvent;
   BOOL		rValue;
   NSPoint	point;

   rValue = [super trackMouse:theEvent inRect:cellFrame
		      ofView:controlView untilMouseUp:flag];

   nEvent = [NSApp currentEvent];
   if ([theEvent type] == NSLeftMouseDown &&
       [nEvent type] == NSLeftMouseUp)
   {
      point = [controlView convertPoint:[theEvent locationInWindow]
			   fromView:nil];
      if (NSPointInRect(point,cellFrame))
      {
	 point = [controlView convertPoint:[nEvent locationInWindow]
			      fromView:nil];
	 if (NSPointInRect(point,cellFrame))
	    [self didClick:nEvent inRect:cellFrame ofView:controlView];
      }
   }
   _mUpEvent = nEvent;
   return rValue;
}

- (void)resetCursorRect:(NSRect)cellFrame inView:(NSView *)controlView
{
   [super resetCursorRect:[self textCellFrameFromRect:cellFrame]
	  inView:controlView];
}

- (void)setEnabled:(BOOL)flag
{
   [_buttonCell setEnabled:flag];
   [super setEnabled:flag];
}

// NSCoding
- (void)encodeWithCoder:(NSCoder *)coder
{
   [super encodeWithCoder:coder];
}

- (id)initWithCoder:(NSCoder *)coder
{
   return [super initWithCoder:coder];
}

@end

@implementation NSComboBoxCell(_Private_)

- (void)_createButtonCell
{
   NSImage	*image;

   image = [self _buttonImage];
   _buttonCell = [[NSButtonCell alloc] initImageCell:image];
   [_buttonCell setImagePosition:NSImageOnly];
   [_buttonCell setButtonType:NSMomentaryPushButton];
   [_buttonCell setHighlightsBy:NSPushInCellMask];
   [_buttonCell setBordered:YES];
   [_buttonCell setTarget:self];
   [_buttonCell setAction: @selector(_didClick:)];
}

- (void)_didClick:(id)sender
{
   NSSize	size;
   NSPoint	point,oldPoint;

   if (![self isEnabled])
      return;

   if (![self controlView])
      control_view = _popView;

   size = [[self _popUp] popUpCellSizeForPopUp:self];
   if (size.width == 0 || size.height == 0)
      return;
   point = _popRect.origin;
   if ([_popView isFlipped])
      point.y += NSHeight(_popRect);
   point = [_popView convertPoint:point toView:nil];
   point.y -= 1.0;
   point = [[_popView window] convertBaseToScreen:point];
   point.y -= size.height;
   if (point.y >= 0)
      goto popUp;

   oldPoint = point;
   point = _popRect.origin;
   if (![_popView isFlipped])
      point.y += NSHeight(_popRect);
   point = [[_popView window] convertBaseToScreen:point];
   if (point.y > NSHeight([[[_popView window] screen] frame]))
      point = oldPoint;

   if (point.y+size.height > NSHeight([[[_popView window] screen] frame]))
      point.y = NSHeight([[[_popView window] screen] frame]) - size.height;

  popUp:

   if (point.x+size.width > NSWidth([[[_popView window] screen] frame]))
      point.x = NSWidth([[[_popView window] screen] frame]) - size.width;
   if (point.x < 0.0)
      point.x = 0.0;

   [[self _popUp] popUpCell:self popUpAt:point width:NSWidth(_popRect)];
}

- (NSImage *)_buttonImage
{
   return [NSImage imageNamed: @"NSComboArrow"];
}

- (NSEvent *)_mouseUpEvent
{
   return _mUpEvent;
   _mUpEvent = nil;
}

- (GSComboWindow *)_popUp
{
   return [GSComboWindow defaultPopUp];
}

@end
