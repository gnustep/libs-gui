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

#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSComboBox.h>
#include <AppKit/NSComboBoxCell.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSScreen.h>

#include "GSComboSupport.h"

static NSNotificationCenter *nc;

@interface NSComboBoxCell(_Private_)
- (NSArray *)_dataSourceObjectValues;
- (void) _didClickInRect: (NSRect)cellFrame
	   ofView: (NSView *)controlView;
- (void) _didClick: (id)sender;
- (GSComboWindow *) _popUp;
@end

@implementation NSComboBoxCell

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSComboBoxCell class])
    {
      [self setVersion: 1];
      nc = [NSNotificationCenter defaultCenter];
    }
}

- (id) initTextCell: (NSString *)aString
{
  self = [super initTextCell: aString];

  // Implicitly set by allocation:
  //
  //_dataSource = nil;
  //_buttonCell = nil;
  _popUpList = [[NSMutableArray alloc] init];
  //_usesDataSource = NO;
  //_completes = NO;
  _hasVerticalScroller = YES;
  _visibleItems = 10;
  _intercellSpacing = NSMakeSize(3.0, 2.0);
  _itemHeight = 16;
  _selectedItem = -1;

  _popRect = NSZeroRect;
  //_mUpEvent = nil;
  _buttonCell = [[NSButtonCell alloc] initImageCell: 
					  [NSImage imageNamed: @"NSComboArrow"]];
  [_buttonCell setImagePosition: NSImageOnly];
  [_buttonCell setButtonType: NSMomentaryPushButton];
  [_buttonCell setHighlightsBy: NSPushInCellMask];
  [_buttonCell setBordered: YES];
  // This never gets used.
  [_buttonCell setTarget: self];
  [_buttonCell setAction: @selector(_didClick:)];

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_dataSource);
  RELEASE(_buttonCell);
  RELEASE(_popUpList);
  
  [super dealloc];
}

- (BOOL) hasVerticalScroller { return _hasVerticalScroller; }
- (void) setHasVerticalScroller: (BOOL)flag
{
  _hasVerticalScroller = flag;
}

- (NSSize) intercellSpacing { return _intercellSpacing; }
- (void) setIntercellSpacing: (NSSize)aSize
{
  _intercellSpacing = aSize;
}

- (float) itemHeight { return _itemHeight; }
- (void) setItemHeight: (float)itemHeight
{
  if (itemHeight > 14)
    _itemHeight = itemHeight;
}

- (int) numberOfVisibleItems { return _visibleItems; }
- (void) setNumberOfVisibleItems: (int)visibleItems
{
  if (_visibleItems > 10)
    _visibleItems = visibleItems;
}

- (void) reloadData
{
// TODO notify popup
}

- (void) noteNumberOfItemsChanged
{
// TODO notify popup
}

- (BOOL) usesDataSource { return _usesDataSource; }
- (void) setUsesDataSource: (BOOL)flag
{
  _usesDataSource = flag;
}

- (void) scrollItemAtIndexToTop: (int)index
{
// TODO
}

- (void) scrollItemAtIndexToVisible: (int)index
{
// TODO
}

- (void) selectItemAtIndex: (int)index
{
  if (index < -1)
    index = -1;

  if (_selectedItem != index)
    {
      _selectedItem = index;
      // TODO: Notify popup
      [nc postNotificationName: NSComboBoxSelectionDidChangeNotification
	  object: [self controlView]
	  userInfo: nil];
    }
}

- (void) deselectItemAtIndex: (int)index
{
  if (_selectedItem == index)
  {
    _selectedItem = -1;
    // TODO: Notify popup
    [nc postNotificationName: NSComboBoxSelectionDidChangeNotification
	object: [self controlView]
	userInfo: nil];
  }
}

- (int) indexOfSelectedItem
{
  return _selectedItem;
}

- (int)numberOfItems
{
  if (_usesDataSource)
    {
      if (!_dataSource)
	NSLog(@"ComboBox: No DataSource Specified");
      else
        {
	  if ([_dataSource respondsToSelector: @selector(numberOfItemsInComboBox:)])
	    {
	      return [_dataSource numberOfItemsInComboBox:
				      (NSComboBox *)[self controlView]];
	    }
	  else
	    {
	      if ([_dataSource respondsToSelector: @selector(numberOfItemsInComboBoxCell:)])
		return [_dataSource numberOfItemsInComboBoxCell: self];
	    }
	}
    }
  else
    return [_popUpList count];
	 
   return 0;
}

- (id) dataSource { return _dataSource; }
- (void) setDataSource: (id)aSource
{
  if (!_usesDataSource)
    NSLog(@"Method Invalid: ComboBox does not use dataSource");
  else
    ASSIGN(_dataSource, aSource);
}

- (void) addItemWithObjectValue: (id)object
{
  if (_usesDataSource)
    NSLog(@"Method Invalid: ComboBox uses dataSource");
  else
    [_popUpList addObject: object];
  [self reloadData];
}

- (void) addItemsWithObjectValues: (NSArray *)objects
{
  if (_usesDataSource)
    NSLog(@"Method Invalid: ComboBox uses dataSource");
  else
    [_popUpList addObjectsFromArray: objects];
  [self reloadData];
}

- (void) insertItemWithObjectValue: (id)object atIndex: (int)index
{
  if (_usesDataSource)
    NSLog(@"Method Invalid: ComboBox uses dataSource");
  else
    [_popUpList insertObject: object atIndex: index];
  [self reloadData];
}

- (void) removeItemWithObjectValue: (id)object
{
  if (_usesDataSource)
    NSLog(@"Method Invalid: ComboBox uses dataSource");
  else
    [_popUpList removeObject: object];
  [self reloadData];
}

- (void) removeItemAtIndex: (int)index
{
  if (_usesDataSource)
    NSLog(@"Method Invalid: ComboBox uses dataSource");
  else
    [_popUpList removeObjectAtIndex: index];
  [self reloadData];
}

- (void) removeAllItems
{
  if (_usesDataSource)
    NSLog(@"Method Invalid: ComboBox uses dataSource");
  else
    [_popUpList removeAllObjects];
  [self reloadData];
}

- (void) selectItemWithObjectValue: (id)object
{
 if (_usesDataSource)
    NSLog(@"Method Invalid: ComboBox uses dataSource");
 else
   {
     int i = [_popUpList indexOfObject: object];

     if (i == NSNotFound)
       i = -1;

     [self selectItemAtIndex: i];
   }
}

- (id) itemObjectValueAtIndex: (int)index
{
  if (_usesDataSource)
    {
      NSLog(@"Method Invalid: ComboBox uses dataSource");
      return nil;
    }
  else
    return [_popUpList objectAtIndex: index];
}

- (id) objectValueOfSelectedItem
{
  if (_usesDataSource)
    {
      NSLog(@"Method Invalid: ComboBox uses dataSource");
      return nil;
    }
  else
    {
      int index = [self indexOfSelectedItem];

      if (index == -1)
	return nil;
      else
	return [_popUpList objectAtIndex: index];
    }
}

- (int) indexOfItemWithObjectValue: (id)object
{
   if (_usesDataSource)
   {
      NSLog(@"Method Invalid: ComboBox uses dataSource");
      return 0;
   }
   return [_popUpList indexOfObject: object];
}

- (NSArray *)objectValues
{
  if (_usesDataSource)
    // FIXME: This should give a warning
    return [self _dataSourceObjectValues];
  return _popUpList;
}

// Text completion
- (NSString *)completedString:(NSString *)substring
{
  if (_usesDataSource)
    {
      if (!_dataSource)
	NSLog(@"ComboBox: No DataSource Specified");
      else if ([_dataSource respondsToSelector: @selector(comboBox:completedString:)])
        {
	  return [_dataSource comboBox: (NSComboBox *)[self controlView] 
			      completedString: substring];
	}
      else if ([_dataSource respondsToSelector: @selector(comboBoxCell:completedString:)])
        {
	  return [_dataSource comboBoxCell: self completedString: substring];
	}
    }
  else
  {
    int i;

    for (i = 0; i < [_popUpList count]; i++)
      {
	// FIXME: How to convert to a string?  
	NSString *str = [[_popUpList objectAtIndex: i] description];

	if ([str hasPrefix: substring])
	  return str;
      }
  }
  return substring;
}

- (void)setCompletes:(BOOL)completes
{
  _completes = completes;
}

- (BOOL)completes
{
  return _completes;
}

#define CBButtonWidth 18
#define CBFrameWidth 2
static inline NSRect 
textCellFrameFromRect(NSRect cellRect)
{
  return NSMakeRect(NSMinX(cellRect),
		    NSMinY(cellRect),
		    NSWidth(cellRect)-CBButtonWidth,
		    NSHeight(cellRect));
}

static inline NSRect 
buttonCellFrameFromRect(NSRect cellRect)
{
  return NSMakeRect(NSMaxX(cellRect)-CBButtonWidth,
		    NSMinY(cellRect)+CBFrameWidth,
		    CBButtonWidth,
		    NSHeight(cellRect)-(CBFrameWidth*2.0));
}

// Overridden
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  if ([GSCurrentContext() isDrawingToScreen])
    {
      [super drawWithFrame: textCellFrameFromRect(cellFrame)
	     inView: controlView];
      [_buttonCell drawWithFrame: buttonCellFrameFromRect(cellFrame)
		   inView: controlView];
    }
  else
    [super drawWithFrame: cellFrame inView: controlView];
}

- (void) highlight: (BOOL)flag
	 withFrame: (NSRect)cellFrame
	    inView: (NSView *)controlView
{
  if ([GSCurrentContext() isDrawingToScreen])
    {
      [super highlight: flag
	     withFrame: textCellFrameFromRect(cellFrame)
	     inView: controlView];
      [_buttonCell highlight: flag
		   withFrame: buttonCellFrameFromRect(cellFrame)
		   inView: controlView];
    }
  else
    [super highlight: flag withFrame: cellFrame inView: controlView];
}

- (void) selectWithFrame: (NSRect)aRect 
		  inView: (NSView *)controlView
		  editor: (NSText *)textObj 
		delegate: (id)anObject
		   start: (int)selStart 
		  length: (int)selLength
{
  [super selectWithFrame: textCellFrameFromRect(aRect)
	 inView: controlView
	 editor: textObj 
	 delegate: anObject
	 start: selStart 
	 length: selLength];
}

- (void) editWithFrame: (NSRect)aRect 
		inView: (NSView *)controlView
		editor: (NSText *)textObj 
	      delegate: (id)anObject
		 event: (NSEvent *)theEvent
{
  [super editWithFrame: textCellFrameFromRect(aRect)
	 inView: controlView
	 editor: textObj 
	 delegate: anObject
	 event: theEvent];
}

- (BOOL) trackMouse: (NSEvent *)theEvent 
	     inRect: (NSRect)cellFrame
	     ofView: (NSView *)controlView 
       untilMouseUp: (BOOL)flag
{
  NSEvent *nEvent;
  BOOL 	rValue;
  NSPoint point;

  // Should this be set by NSActionCell ?
  if (_control_view != controlView)
    _control_view = controlView;

  rValue = [super trackMouse: theEvent inRect: cellFrame
		  ofView: controlView untilMouseUp: flag];

  nEvent = [NSApp currentEvent];
  if ([theEvent type] == NSLeftMouseDown &&
      [nEvent type] == NSLeftMouseUp)
    {
      point = [controlView convertPoint: [theEvent locationInWindow]
			   fromView: nil];
      if (NSPointInRect(point, cellFrame))
        {
	  point = [controlView convertPoint: [nEvent locationInWindow]
			       fromView: nil];
	  if (NSPointInRect(point, buttonCellFrameFromRect(cellFrame)))
//      [_buttonCell performClick: self];
	    [self _didClickInRect: cellFrame ofView: controlView];
	}
    }
  _mUpEvent = nEvent;
  
  return rValue;
}

- (void) resetCursorRect: (NSRect)cellFrame inView: (NSView *)controlView
{
   [super resetCursorRect: textCellFrameFromRect(cellFrame)
	  inView: controlView];
}

- (void) setEnabled: (BOOL)flag
{
   [_buttonCell setEnabled: flag];
   [super setEnabled: flag];
}

// NSCoding
- (void) encodeWithCoder: (NSCoder *)coder
{
  [super encodeWithCoder: coder];

  [coder encodeValueOfObjCType: @encode(id) at: &_buttonCell];
  [coder encodeValueOfObjCType: @encode(id) at: &_popUpList];
  [coder encodeValueOfObjCType: @encode(BOOL) at: &_usesDataSource];
  [coder encodeValueOfObjCType: @encode(BOOL) at: &_hasVerticalScroller];
  [coder encodeValueOfObjCType: @encode(BOOL) at: &_completes];
  [coder encodeValueOfObjCType: @encode(BOOL) at: &_usesDataSource];
  [coder encodeValueOfObjCType: @encode(int) at: &_visibleItems];
  [coder encodeValueOfObjCType: @encode(NSSize) at: &_intercellSpacing];
  [coder encodeValueOfObjCType: @encode(float) at: &_itemHeight];
  [coder encodeValueOfObjCType: @encode(int) at: &_selectedItem];

  if (_usesDataSource == YES)
    [coder encodeValueOfObjCType: @encode(id) at: &_dataSource];      
}

- (id) initWithCoder: (NSCoder *)coder
{
  self = [super initWithCoder: coder];
  
  [coder decodeValueOfObjCType: @encode(id) at: &_buttonCell];
  [coder decodeValueOfObjCType: @encode(id) at: &_popUpList];
  [coder decodeValueOfObjCType: @encode(BOOL) at: &_usesDataSource];
  [coder decodeValueOfObjCType: @encode(BOOL) at: &_hasVerticalScroller];
  [coder decodeValueOfObjCType: @encode(BOOL) at: &_completes];
  [coder decodeValueOfObjCType: @encode(BOOL) at: &_usesDataSource];
  [coder decodeValueOfObjCType: @encode(int) at: &_visibleItems];
  [coder decodeValueOfObjCType: @encode(NSSize) at: &_intercellSpacing];
  [coder decodeValueOfObjCType: @encode(float) at: &_itemHeight];
  [coder decodeValueOfObjCType: @encode(int) at: &_selectedItem];

  if (_usesDataSource == YES)
    [coder decodeValueOfObjCType: @encode(id) at: &_dataSource];      

  return self;
}

@end

@implementation NSComboBoxCell(_Private_)

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

- (void) _didClickInRect: (NSRect)cellFrame
		  ofView: (NSView *)controlView
{
  // We can not use performClick: on the button cell here as 
  // the button uses only part of the bounds of the control view.
  NSWindow *cvWin = [controlView window];
      
  [_buttonCell highlight: YES 
	       withFrame: buttonCellFrameFromRect(cellFrame) 
	       inView: controlView];
  [cvWin flushWindow];

  _popRect = cellFrame;

  [self _didClick: self];
  _popRect = NSZeroRect;
  
  [_buttonCell highlight: NO 
	       withFrame: buttonCellFrameFromRect(cellFrame) 
	       inView: controlView];
  [cvWin flushWindow];
}

- (void) _didClick: (id)sender
{
  NSSize size;
  NSPoint point,oldPoint;
  NSRect screenFrame;
  NSView *popView = [self controlView];

  if (_cell.is_disabled)
    return;

  size = [[self _popUp] popUpCellSizeForPopUp: self];
  if (size.width == 0 || size.height == 0)
    return;

  screenFrame = [[[popView window] screen] frame];
  point = _popRect.origin;
  if ([popView isFlipped])
    point.y += NSHeight(_popRect);
  point = [popView convertPoint: point toView: nil];
  point.y -= 1.0;
  point = [[popView window] convertBaseToScreen: point];
  point.y -= size.height;
  if (point.y < 0)
    {
      // Off screen, so move it.
      oldPoint = point;
      point = _popRect.origin;
      if (![popView isFlipped])
	  point.y += NSHeight(_popRect);
      point = [popView convertPoint: point toView: nil];
      point.y += 1.0;
      point = [[popView window] convertBaseToScreen: point];
      if (point.y > NSHeight(screenFrame))
	  point = oldPoint;
      
      if (point.y + size.height > NSHeight(screenFrame))
	  point.y = NSHeight(screenFrame) - size.height;
    }

  if (point.x + size.width > NSWidth(screenFrame))
    point.x = NSWidth(screenFrame) - size.width;
  if (point.x < 0.0)
    point.x = 0.0;

  [nc postNotificationName: NSComboBoxWillPopUpNotification
      object: popView
      userInfo: nil];

  [[self _popUp] popUpCell: self popUpAt: point width: NSWidth(_popRect)];

  [nc postNotificationName: NSComboBoxWillDismissNotification
      object: popView
      userInfo: nil];
}

- (NSEvent *)_mouseUpEvent
{
   return _mUpEvent;
}

- (GSComboWindow *)_popUp
{
   return [GSComboWindow defaultPopUp];
}

@end
