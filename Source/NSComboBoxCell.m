/** <title>NSComboBoxCell</title>

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
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSException.h>
#include <Foundation/NSAutoreleasePool.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSComboBox.h>
#include <AppKit/NSComboBoxCell.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSScroller.h>

@interface GSComboWindow : NSPanel
{
   NSBrowser	*browser;

@private;
   NSComboBoxCell *_cell;
   BOOL		_stopped;
}

+ (GSComboWindow *)defaultPopUp;

- (void) positionForCell:(NSComboBoxCell *)aCell
		    view: (NSView *)popView;
- (NSSize) popUpCellSizeForPopUp:(NSComboBoxCell *)aCell
			   width: (float) width;
- (void) popUpForCell: (NSComboBoxCell *)aCell
		 view: (NSView *)popView;
- (void) runModalPopUp;
- (void) runLoop;
- (void) reloadData;
- (void) noteNumberOfItemsChanged;
- (void) scrollItemAtIndexToTop: (int)index;
- (void) scrollItemAtIndexToVisible: (int)index;
- (void) selectItemAtIndex: (int)index;
- (void) deselectItemAtIndex: (int)index;

@end


static NSNotificationCenter *nc;

@interface NSComboBoxCell(_Private_)
- (NSString *) _stringValueAtIndex: (int)index;
- (void) _didClickInRect: (NSRect)cellFrame
	   ofView: (NSView *)controlView;
- (void) _didClick: (id)sender;
- (GSComboWindow *) _popUp;
@end


@implementation GSComboWindow

+ (GSComboWindow *) defaultPopUp
{
  static GSComboWindow *gsWindow = nil;

  if (!gsWindow)
    gsWindow = [[self alloc] initWithContentRect: NSMakeRect(0,0,100,100)
			     styleMask: NSBorderlessWindowMask
			     backing: NSBackingStoreNonretained //NSBackingStoreBuffered
			     defer: YES];
  return gsWindow;
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
{
  NSBox *box;
   
  self = [super initWithContentRect: contentRect
		styleMask: aStyle
		backing: bufferingType
		defer: flag];
  [self setLevel: NSPopUpMenuWindowLevel];
  [self setWorksWhenModal: YES];
  [self setBecomesKeyOnlyIfNeeded: YES];

  box = [[NSBox alloc] initWithFrame: contentRect];
  [box setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box setBorderType: NSLineBorder];
  [box setTitlePosition: NSNoTitle];
  [box setContentViewMargins: NSMakeSize(1,1)];
  [box sizeToFit];
  [self setContentView: box];
  RELEASE(box);
  browser = [[NSBrowser alloc] initWithFrame: contentRect];
  [browser setMaxVisibleColumns: 1];
  [browser setTitled: NO];
  [browser setHasHorizontalScroller: NO];
  [browser setTarget: self];
  [browser setAction: @selector(selectItem:)];
  [browser setDelegate: self];
//    [browser setRefusesFirstResponder: YES];
  [browser setAutoresizingMask: NSViewWidthSizable | NSViewWidthSizable];
  [browser setAllowsEmptySelection: NO];
  [browser setAllowsMultipleSelection: NO];
  [browser setReusesColumns: YES];
  // Create an empty matrix
  [browser loadColumnZero];
  [box setContentView: browser];
  RELEASE(browser);
  
  return self;
}

- (BOOL) canBecomeKeyWindow { return YES; }

- (void)dealloc
{
  // Browser was not retained so don't release it
  [super dealloc];
}

- (NSSize) popUpCellSizeForPopUp: (NSComboBoxCell *)aCell 
			   width: (float) width
{
  NSMatrix *matrix = [browser matrixInColumn: 0];
  NSSize size;
  NSSize bsize = _sizeForBorderType(NSLineBorder);
  float itemHeight;
  float cellSpacing;
  int num = [aCell numberOfItems];
  int max = [aCell numberOfVisibleItems];

  if (num > max)
    num = max;

  itemHeight = [aCell itemHeight];
  if (itemHeight <= 0)
    {
      itemHeight = [matrix cellSize].height;
    }
  else 
    {
      size.height = itemHeight;
      if ([aCell hasVerticalScroller])
        {
	  size.width = width - [NSScroller scrollerWidth] - bsize.width;
	}
      else 
        {
	  size.width = width - bsize.width;
	}
      [matrix setCellSize: size];
    }

  size = [aCell intercellSpacing];
  cellSpacing = size.height;
  if (cellSpacing <= 0)
    cellSpacing = [matrix intercellSpacing].height;
  else 
    [matrix setIntercellSpacing: size];

  return NSMakeSize(width, 2.0 + bsize.height + (itemHeight + cellSpacing) * num);
}

- (void) positionForCell: (NSComboBoxCell *)aCell
		    view: (NSView *)popView
{
  NSRect popRect = [popView bounds];
  NSRect screenFrame;
  NSRect rect;
  NSSize size;
  NSPoint point, oldPoint;
   
  size = [self popUpCellSizeForPopUp: aCell width: NSWidth(popRect)];
  if (size.width == 0 || size.height == 0)
    return;

  screenFrame = [[[popView window] screen] frame];
  point = popRect.origin;
  if ([popView isFlipped])
    point.y += NSHeight(popRect);
  point = [popView convertPoint: point toView: nil];
  point.y -= 1.0;
  point = [[popView window] convertBaseToScreen: point];
  point.y -= size.height;
  if (point.y < 0)
    {
      // Off screen, so move it.
      oldPoint = point;
      point = popRect.origin;
      if (![popView isFlipped])
	  point.y += NSHeight(popRect);
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

  rect.size = size;
  rect.origin.x = point.x;
  rect.origin.y = point.y;
  rect = [NSWindow frameRectForContentRect: rect
		   styleMask: _styleMask];
  [self setFrame: rect display: NO];
}

- (void) popUpForCell: (NSComboBoxCell *)aCell
	   view: (NSView *)popView
{
  [self positionForCell: aCell
	view: popView];

  _cell = aCell;
  [self reloadData];
  
//    [self enableKeyEquivalentForDefaultButtonCell];
  [self runModalPopUp];

  _cell = nil;
}

- (void) runModalPopUp
{
  NSWindow	*onWindow;
  NSEvent	*event;
  NSException	*exception = nil;
  
  onWindow = [[_cell controlView] window];
//  [self setLevel: [onWindow level]];
//  [self orderWindow: NSWindowAbove relativeTo: [onWindow windowNumber]];

  while ((event = [NSApp nextEventMatchingMask: NSAnyEventMask
			 untilDate: [NSDate dateWithTimeIntervalSinceNow: 0]
			 inMode: NSDefaultRunLoopMode
			 dequeue: NO]))
    {
      if ([event type] == NSAppKitDefined ||
	  [event type] == NSSystemDefined ||
	  [event type] == NSApplicationDefined ||
	  [event windowNumber] == [self windowNumber])
	break;
      [NSApp nextEventMatchingMask: NSAnyEventMask
	     untilDate: [NSDate distantFuture]
	     inMode: NSDefaultRunLoopMode
	     dequeue: YES];
    }

  [self makeKeyAndOrderFront: nil];

  NS_DURING
    [self runLoop];
  NS_HANDLER
    exception = localException;
  NS_ENDHANDLER;

  if (onWindow)
    {
      [onWindow makeKeyWindow];
      [onWindow orderFrontRegardless];
    }

  if ([self isVisible])
      [self orderOut:nil];

  if (exception)
    [exception raise];
}

- (void) runLoop
{
  NSEvent		*event;
  int			cnt = 0;
  BOOL			kDown;
  NSDate *limit = [NSDate distantFuture];
  CREATE_AUTORELEASE_POOL (pool);
  
  _stopped = NO;
  while (!_stopped)
    {
      kDown = NO;
      cnt++;
      if (cnt >= 5)
        {
	  RELEASE(pool);
	  IF_NO_GC(pool = [[NSAutoreleasePool alloc] init]);
	  cnt = 0;
	}
      event = [NSApp nextEventMatchingMask: NSAnyEventMask
		     untilDate: limit
		     inMode: NSDefaultRunLoopMode
		     dequeue: NO];
      if (event)
        {
	  if ([event type] == NSAppKitDefined ||
	      [event type] == NSSystemDefined ||
	      [event type] == NSApplicationDefined ||
	      [event windowNumber] == [self windowNumber])
	    {
	      event = [NSApp nextEventMatchingMask: NSAnyEventMask
			     untilDate: limit
			     inMode: NSDefaultRunLoopMode
			     dequeue: YES];
	      [NSApp sendEvent: event];
	      if ([event type] == NSKeyDown)
		  kDown = YES;
	    }
	  else if ([event type] == NSMouseMoved ||
		   [event type] == NSLeftMouseDragged ||
		   [event type] == NSOtherMouseDragged ||
		   [event type] == NSRightMouseDragged ||
		   [event type] == NSMouseEntered ||
		   [event type] == NSMouseExited ||
		   [event type] == NSCursorUpdate)
	    {
	      event = [NSApp nextEventMatchingMask: NSAnyEventMask
			     untilDate: limit
			     inMode: NSDefaultRunLoopMode
			     dequeue: YES];
	      [NSApp sendEvent:event];
	    }
	  else
	    _stopped = YES;
	}
    }

  if (kDown)
    while ((event = [NSApp nextEventMatchingMask: NSAnyEventMask
			   untilDate: limit
			   inMode: NSDefaultRunLoopMode
			   dequeue: NO]))
      {
	if ([event windowNumber] != [self windowNumber])
	  break;
	event = [NSApp nextEventMatchingMask: NSAnyEventMask
		       untilDate: limit
		       inMode: NSDefaultRunLoopMode
		       dequeue: YES];
	[NSApp sendEvent: event];
	if ([event type] == NSKeyUp)
	  break;
      }
  RELEASE(pool);
}

- (void) reloadData
{
  [browser loadColumnZero];
  [self selectItemAtIndex: [_cell indexOfSelectedItem]];
}

- (void) noteNumberOfItemsChanged
{
// FIXME: Should only load the additional items
  [self reloadData];
}

- (void) scrollItemAtIndexToTop: (int)index
{
  NSMatrix *matrix = [browser matrixInColumn: 0];
  NSRect rect;

  rect = [matrix cellFrameAtRow: index column: 0];
  [matrix scrollPoint: rect.origin];
}

- (void) scrollItemAtIndexToVisible: (int)index
{
  NSMatrix *matrix = [browser matrixInColumn: 0];

  [matrix scrollCellToVisibleAtRow: index column: 0];
}

- (void) selectItemAtIndex: (int)index
{
  [browser selectRow: index inColumn: 0];
}

- (void) deselectItemAtIndex: (int)index
{
  NSMatrix *matrix = [browser matrixInColumn: 0];

  [matrix deselectSelectedCell];
}

// Target/Action of Browser
- (void) selectItem: (id)sender
{
  if (_cell)
    {
      [_cell selectItemAtIndex: [sender selectedRowInColumn: 0]];
      [_cell setStringValue: [[sender selectedCell] stringValue]];
      _stopped = YES;
    }
}

// Browser Delegate Methods
- (int) browser: (NSBrowser *)sender 
numberOfRowsInColumn: (int)column
{
  if (!_cell)
    return 0;

  return [_cell numberOfItems];
}

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)aCell
	   atRow: (int)row 
	  column: (int)column
{
  if (!_cell)
    return;

  [aCell setStringValue: [_cell _stringValueAtIndex: row]];
  [aCell setLeaf: YES];
}

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
  //_usesDataSource = NO;
  //_completes = NO;
  _popUpList = [[NSMutableArray alloc] init];
  _hasVerticalScroller = YES;
  _visibleItems = 10;
  _intercellSpacing = NSMakeSize(3.0, 2.0);
  _itemHeight = 16;
  _selectedItem = -1;

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
  if (visibleItems > 10)
    _visibleItems = visibleItems;
}

- (void) reloadData
{
  [_popup reloadData];
}

- (void) noteNumberOfItemsChanged
{
  [_popup noteNumberOfItemsChanged];
}

- (BOOL) usesDataSource { return _usesDataSource; }
- (void) setUsesDataSource: (BOOL)flag
{
  _usesDataSource = flag;
}

- (void) scrollItemAtIndexToTop: (int)index
{
  [_popup scrollItemAtIndexToTop: index];
}

- (void) scrollItemAtIndexToVisible: (int)index
{
  [_popup scrollItemAtIndexToVisible: index];
}

- (void) selectItemAtIndex: (int)index
{
  if (index < -1)
    index = -1;

  if (_selectedItem != index)
    {
      _selectedItem = index;
      
      [_popup selectItemAtIndex: index];

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

      [_popup deselectItemAtIndex: index];

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
    {
      NSLog(@"Method Invalid: ComboBox uses dataSource");
      return nil;
    }
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
  if ([theEvent type] == NSLeftMouseDown  &&
      [nEvent type] == NSLeftMouseUp)
    {
      point = [controlView convertPoint: [theEvent locationInWindow]
			   fromView: nil];
      if (NSPointInRect(point, cellFrame))
        {
	  point = [controlView convertPoint: [nEvent locationInWindow]
			       fromView: nil];
	  if (NSPointInRect(point, buttonCellFrameFromRect(cellFrame)))
 	    {
//      [_buttonCell performClick: self];
	      [self _didClickInRect: cellFrame ofView: controlView];
	    }
	}
    }
  
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
    [coder encodeConditionalObject: _dataSource];      
}

- (id) initWithCoder: (NSCoder *)coder
{
  BOOL dummy;
  
  self = [super initWithCoder: coder];
  
  [coder decodeValueOfObjCType: @encode(id) at: &_buttonCell];
  RETAIN(_buttonCell);
  [coder decodeValueOfObjCType: @encode(id) at: &_popUpList];
  RETAIN(_popUpList);
  [coder decodeValueOfObjCType: @encode(BOOL) at: &_usesDataSource];
  [coder decodeValueOfObjCType: @encode(BOOL) at: &_hasVerticalScroller];
  [coder decodeValueOfObjCType: @encode(BOOL) at: &_completes];
  [coder decodeValueOfObjCType: @encode(BOOL) at: &dummy];
  [coder decodeValueOfObjCType: @encode(int) at: &_visibleItems];
  [coder decodeValueOfObjCType: @encode(NSSize) at: &_intercellSpacing];
  [coder decodeValueOfObjCType: @encode(float) at: &_itemHeight];
  [coder decodeValueOfObjCType: @encode(int) at: &_selectedItem];

  if (_usesDataSource == YES)
    [self setDataSource: [coder decodeObject]];      

  return self;
}

@end

@implementation NSComboBoxCell(_Private_)

- (NSString *)_stringValueAtIndex: (int)index
{
  if (!_usesDataSource)
    {
      return [[self itemObjectValueAtIndex: index] description];
    }
  else
    {
      if (!_dataSource)
        {
	  NSLog(@"ComboBox: No DataSource Specified");
	  return nil;
	}
      if ([_dataSource respondsToSelector: 
			   @selector(comboBox:objectValueForItemAtIndex:)])
        {
	  return [[_dataSource comboBox: (NSComboBox *)[self controlView] 
			       objectValueForItemAtIndex: index] description];
	}
      else if ([_dataSource respondsToSelector: 
				@selector(comboBoxCell:objectValueForItemAtIndex:)])
        {
	  return [[_dataSource comboBoxCell: self
			      objectValueForItemAtIndex: index] description];
	}
    }

  return nil;
}

- (void) _didClickInRect: (NSRect)cellFrame
		  ofView: (NSView *)controlView
{
  // We can not use performClick: on the button cell here as 
  // the button uses only part of the bounds of the control view.
  NSWindow *cvWin = [controlView window];

  [controlView lockFocus];
  [_buttonCell highlight: YES 
	       withFrame: buttonCellFrameFromRect(cellFrame) 
	       inView: controlView];
  [controlView unlockFocus];
  [cvWin flushWindow];

  [self _didClick: self];
  
  [controlView lockFocus];
  [_buttonCell highlight: NO 
	       withFrame: buttonCellFrameFromRect(cellFrame) 
	       inView: controlView];
  [controlView unlockFocus];
  [cvWin flushWindow];

}

- (void) _didClick: (id)sender
{
  NSView *popView = [self controlView];

  if ((_cell.is_disabled) || (popView == nil))
    return;

  [nc postNotificationName: NSComboBoxWillPopUpNotification
      object: popView
      userInfo: nil];

  // HACK Abort the editing, otherwise the selected value is
  // overwritten by the editor
  //if ([_control_view isKindOfClass: NSControl])
  [(NSControl *)_control_view abortEditing];

  _popup = [self _popUp];
  [_popup popUpForCell: self view: popView];
  _popup = nil;

  [nc postNotificationName: NSComboBoxWillDismissNotification
      object: popView
      userInfo: nil];
}

- (GSComboWindow *)_popUp
{
  return [GSComboWindow defaultPopUp];
}

@end
