/** <title>NSComboBoxCell</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Gerrit van Dyk <gerritvd@decillion.net>
   Date: 1999
   Author:  Quentin Mathe <qmathe@club-internet.fr>
   Date: 2004

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
#include <Foundation/NSValue.h>
#include "AppKit/NSApplication.h"
#include "AppKit/NSBox.h"
#include "AppKit/NSBrowser.h"
#include "AppKit/NSBrowserCell.h"
#include "AppKit/NSButtonCell.h"
#include "AppKit/NSComboBox.h"
#include "AppKit/NSComboBoxCell.h"
#include "AppKit/NSGraphicsContext.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSMatrix.h"
#include "AppKit/NSPanel.h"
#include "AppKit/NSScreen.h"
#include "AppKit/NSScroller.h"
#include "AppKit/NSScrollView.h"
#include "AppKit/NSTableColumn.h"
#include "AppKit/NSTableView.h"
#include "AppKit/NSTextView.h"

static NSNotificationCenter *nc;
static const BOOL ForceBrowser = NO;
static const BOOL ForceArrowIcon = NO;


@interface GSFirstMouseTableView : NSTableView
{

}

@end

@implementation GSFirstMouseTableView
- (BOOL) acceptsFirstMouse: (NSEvent *)event
{
  return YES;
}
@end

@interface GSComboWindow : NSPanel
{
   NSBrowser *_browser;
   GSFirstMouseTableView *_tableView;
   NSComboBoxCell *_cell;
   BOOL _stopped;
   BOOL _localSelection;
}

+ (GSComboWindow *)defaultPopUp;

- (void) layoutWithComboBoxCell:(NSComboBoxCell *)comboBoxCell;
- (void) positionWithComboBoxCell:(NSComboBoxCell *)comboBoxCell;
- (void) popUpForComboBoxCell: (NSComboBoxCell *)comboBoxCell;
- (void) runModalPopUpWithComboBoxCell:(NSComboBoxCell *)comboBoxCell;
- (void) runLoopWithComboBoxCell:(NSComboBoxCell *)comboBoxCell;
- (void) onWindowEdited: (NSNotification *)notification;
- (void) reloadData;
- (void) noteNumberOfItemsChanged;
- (void) scrollItemAtIndexToTop: (int)index;
- (void) scrollItemAtIndexToVisible: (int)index;
- (void) selectItemAtIndex: (int)index;
- (void) deselectItemAtIndex: (int)index;
- (void) moveUpSelection;
- (void) moveDownSelection;
- (void) validateSelection;

@end

@interface NSComboBoxCell (GNUstepPrivate)
- (NSString *) _stringValueAtIndex: (int)index;
- (void) _performClickWithFrame: (NSRect)cellFrame inView: (NSView *)controlView;
- (void) _didClickWithinButton: (id)sender;
- (BOOL) _isWantedEvent: (NSEvent *)event;
- (GSComboWindow *) _popUp;
- (NSRect) _textCellFrame;
- (void) _setSelectedItem: (int)index;
- (void) _loadButtonCell;
@end

// ---

static GSComboWindow *gsWindow = nil;

@implementation GSComboWindow

+ (GSComboWindow *) defaultPopUp
{
  if (!gsWindow)
    gsWindow = [[self alloc] initWithContentRect: NSMakeRect(0,0,200,200)
			               styleMask: NSBorderlessWindowMask
			                 backing: NSBackingStoreNonretained // NSBackingStoreBuffered
			                   defer: YES];
  return gsWindow;
}

- (id) initWithContentRect: (NSRect)contentRect
		 styleMask: (unsigned int)aStyle
		   backing: (NSBackingStoreType)bufferingType
		     defer: (BOOL)flag
{
  NSBox *box;
  NSScrollView *scrollView;
  NSRect borderRect;
   
  self = [super initWithContentRect: contentRect
		          styleMask: aStyle
		            backing: bufferingType
		              defer: flag];	  
  [self setLevel: NSPopUpMenuWindowLevel];
  [self setBecomesKeyOnlyIfNeeded: YES];
  
  _localSelection = NO;
  
  box = [[NSBox alloc] initWithFrame: contentRect];
  [box setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [box setBorderType: NSLineBorder];
  [box setTitlePosition: NSNoTitle];
  [box setContentViewMargins: NSMakeSize(0, 0)];
  [self setContentView: box];
  borderRect = contentRect;
  RELEASE(box);
  
  if (!ForceBrowser)
    {
  _tableView = [[GSFirstMouseTableView alloc] initWithFrame: NSMakeRect(0, 0, 100, 100)];
  [_tableView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  //[_tableView setBackgroundColor: [NSColor whiteColor]];
  [_tableView setDrawsGrid: NO];
  [_tableView setAllowsEmptySelection: YES];
  [_tableView setAllowsMultipleSelection: NO];
  [_tableView setAutoresizesAllColumnsToFit: YES];
  [_tableView setHeaderView: nil];
  [_tableView setCornerView: nil];
  [_tableView addTableColumn: [[NSTableColumn alloc] initWithIdentifier: @"content"]];
  [[_tableView tableColumnWithIdentifier:@"content"]  setDataCell: [[NSCell alloc] initTextCell: @""]];
  [_tableView setDataSource: self];
  [_tableView setDelegate: self];
  
  scrollView = [[NSScrollView alloc] initWithFrame: NSMakeRect(borderRect.origin.x, 
                                                               borderRect.origin.y,
				                             borderRect.size.width, 
						          borderRect.size.height)];
  [scrollView setHasVerticalScroller: YES];
  [scrollView setDocumentView: _tableView];
  [box setContentView: scrollView];
  
  [_tableView reloadData];
    }
  else
    {
  _browser = [[NSBrowser alloc] initWithFrame: NSMakeRect(borderRect.origin.x, 
                                                          borderRect.origin.y,
				                        borderRect.size.width, 
						     borderRect.size.height)];
  [_browser setMaxVisibleColumns: 1];
  [_browser setTitled: NO];
  [_browser setHasHorizontalScroller: NO];
  [_browser setTarget: self];
  [_browser setAction: @selector(selectItem:)];
  [_browser setDelegate: self];
  [_browser setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [_browser setAllowsEmptySelection: YES];
  [_browser setAllowsMultipleSelection: NO];
  [_browser setReusesColumns: YES];
  // Create an empty matrix
  [_browser loadColumnZero];
  [box setContentView: _browser];
    }

  return self;
}

- (BOOL) canBecomeKeyWindow { return YES; }

- (void)dealloc
{
  // browser, table view and scroll view were not retained so don't release them
  [super dealloc];
}

- (void) layoutWithComboBoxCell: (NSComboBoxCell *)comboBoxCell
{
  NSMatrix *matrix = [_browser matrixInColumn: 0];
  NSSize bsize = _sizeForBorderType(NSLineBorder);
  NSSize size;
  float itemHeight;
  float textCellWidth;
  NSSize intercellSpacing;
  int num = [comboBoxCell numberOfItems];
  int max = [comboBoxCell numberOfVisibleItems];
  
  // Manage table view or browser cells height
  
  itemHeight = [comboBoxCell itemHeight];
  if (itemHeight <= 0)
    {
      // FIX ME : raise NSException
      if (!ForceBrowser)
        {
      itemHeight = [_tableView rowHeight];
        }
      else
        {
      itemHeight = [matrix cellSize].height;
        }
    }
  size.height = itemHeight;
    
  // Manage table view or browser cells width
  
  textCellWidth = [comboBoxCell _textCellFrame].size.width;
  if ([comboBoxCell hasVerticalScroller])
    {
      size.width = textCellWidth - [NSScroller scrollerWidth] - bsize.width;
    }
  else 
    {
      size.width = textCellWidth - bsize.width;
    }
  if (size.width < 0)
    {
      size.width = 0;
    }
   
  if (!ForceBrowser)
    {
  [_tableView setRowHeight: size.height];
    }
  else
    {
  [matrix setCellSize: size];
    }
    
  // Just check intercell spacing

  intercellSpacing = [comboBoxCell intercellSpacing];
  if (intercellSpacing.height <= 0)
    {
      // FIX ME : raise NSException
      if (!ForceBrowser)
        {
      intercellSpacing.height = [_tableView intercellSpacing].height;
        }
      else
        {
      intercellSpacing.height = [matrix intercellSpacing].height;
	}
    }
  else 
    {
      if (!ForceBrowser)
        {
      [_tableView setIntercellSpacing: intercellSpacing];
        }
      else
        {
      [matrix setIntercellSpacing: intercellSpacing];
        }
    }
    
    
  if (num > max)
    num = max;
   
  [self setFrame: NSMakeRect(0, 0, textCellWidth, 
     2 * bsize.height + (itemHeight + intercellSpacing.height) * (num - 1)
     + itemHeight) display: NO];
}

- (void) positionWithComboBoxCell: (NSComboBoxCell *)comboBoxCell
{
  NSView *viewWithComboCell = [comboBoxCell controlView];
  NSRect screenFrame;
  NSRect comboWindowFrame;
  NSRect viewWithComboCellFrame;
  NSRect rect;
  NSPoint point, oldPoint;
  NSView *superview = [viewWithComboCell superview];
   
  [self layoutWithComboBoxCell: comboBoxCell];
  
  // Now we can ask for the size
  
  comboWindowFrame = [self frame];
  if (comboWindowFrame.size.width == 0 || comboWindowFrame.size.height == 0)
    return;
  
  screenFrame = [[[viewWithComboCell window] screen] frame];
  viewWithComboCellFrame = [viewWithComboCell frame];
  
  point = viewWithComboCellFrame.origin;
  
  // Switch to the window coordinates
  point = [[viewWithComboCell superview] convertPoint: point toView: nil];
  
  // Switch to the screen coordinates
  point = [[viewWithComboCell window] convertBaseToScreen: point];
  
  // Take in account flipped view
  if ([superview isFlipped])
    point.y += NSHeight([superview frame]) 
      - (viewWithComboCellFrame.origin.y * 2 + NSHeight(viewWithComboCellFrame));
  
  point.y -= 1 + NSHeight(comboWindowFrame);
  
  if (point.y < 0)
    {
      // Off screen, so move it
      oldPoint = point;
      
      point = viewWithComboCellFrame.origin;
      point.y = NSMaxY(viewWithComboCellFrame);
      
      // Switch to the window coordinates  
      point = [[viewWithComboCell superview] convertPoint: point toView: nil];
  
      // Switch to the screen coordiantes
      point = [[viewWithComboCell window] convertBaseToScreen: point];
        
      // Take in account flipped view
      if ([superview isFlipped])
        point.y += NSHeight([superview frame]) 
          - (viewWithComboCellFrame.origin.y * 2 + NSHeight(viewWithComboCellFrame));
	
      point.y += 1;  
      
      if (point.y + NSHeight(comboWindowFrame) > NSHeight(screenFrame))
	  point = oldPoint;
    }

  rect.size.width = NSWidth(comboWindowFrame);
  rect.size.height = NSHeight(comboWindowFrame);
  rect.origin.x = point.x;
  rect.origin.y = point.y;
  [self setFrame: rect display: NO];
}

- (void) popUpForComboBoxCell: (NSComboBoxCell *)comboBoxCell
{
  NSString *more;
  unsigned int index = NSNotFound;
  
   _cell = comboBoxCell;
   
  [self positionWithComboBoxCell: _cell];
  more = [_cell completedString: [_cell stringValue]];
  index = [[_cell objectValues] indexOfObject: more];
  if (index != NSNotFound)
    {
      [_cell _setSelectedItem: index];
    }
    
  [self reloadData];
  [self enableKeyEquivalentForDefaultButtonCell];
  [self runModalPopUpWithComboBoxCell: _cell];

  _cell = nil;
}

- (void) runModalPopUpWithComboBoxCell: (NSComboBoxCell *)comboBoxCell
{
  NSWindow	*onWindow;
  
  onWindow = [[_cell controlView] window];

  [nc addObserver: self selector: @selector(onWindowEdited:) 
    name: NSWindowWillMoveNotification object: onWindow];
  [nc addObserver: self selector: @selector(onWindowEdited:) 
    name: NSWindowWillMiniaturizeNotification object: onWindow];
  /* the notification below doesn't exist currently
  [nc addObserver: self selector: @selector(onWindowEdited:) 
    name: NSWindowWillResizeNotification object: onWindow];
  */
  [nc addObserver: self selector: @selector(onWindowEdited:) 
    name: NSWindowWillCloseNotification object: onWindow];
   
  // ### Hack 
  // ### The code below must be removed when the notifications over will work
  [nc addObserver: self selector: @selector(onWindowEdited:) 
    name: NSWindowDidMoveNotification object: onWindow];
  [nc addObserver: self selector: @selector(onWindowEdited:) 
    name: NSWindowDidMiniaturizeNotification object: onWindow];
  [nc addObserver: self selector: @selector(onWindowEdited:) 
    name: NSWindowDidResizeNotification object: onWindow];
  // ###
  
  [self orderFront: self];
  [self makeFirstResponder: _tableView];
  [self runLoopWithComboBoxCell: comboBoxCell];
  
  [nc removeObserver: self];
  [_tableView setDelegate: self];
  // Hack
  // Need to reset the delegate to receive the next notifications
  
  [self close];

  [onWindow makeFirstResponder: [_cell controlView]];
}

- (void) runLoopWithComboBoxCell: (NSComboBoxCell *)comboBoxCell
{
  NSEvent *event;
  NSDate *limit = [NSDate distantFuture];
  unichar key;
  CREATE_AUTORELEASE_POOL (pool);

  while (YES)
    {
      event = [NSApp nextEventMatchingMask: NSAnyEventMask
		                 untilDate: limit
		                    inMode: NSDefaultRunLoopMode
		                   dequeue: YES];
      if ([event type] == NSLeftMouseDown
       || [event type] == NSRightMouseDown)
        {		   
          if (![comboBoxCell _isWantedEvent: event] && [event window] != self)
	    {
              break;
	    }
	  else
	    {
	      [NSApp sendEvent: event];
	    }
        }
      else if ([event type] == NSKeyDown)
        {
	  key = [[event characters] characterAtIndex: 0];
          if (key == NSUpArrowFunctionKey)
            {
              [self moveUpSelection]; 
            }
          else if (key == NSDownArrowFunctionKey)
            {
              [self moveDownSelection];
            }
          else if (key == NSNewlineCharacter 
	    || key == NSEnterCharacter 
	    || key == NSCarriageReturnCharacter)
            {
              [self validateSelection];
            }
          else
            {
	      [NSApp sendEvent: event];
	    }
	}
      else
        {
	  [NSApp sendEvent: event];
	}
      
      if (_stopped)
        break;      
    }
    
  _stopped = NO;
    
  RELEASE(pool);
}

// onWindow notifications

- (void) onWindowEdited: (NSNotification *)notification
{
  _stopped = YES;
}

- (void) reloadData
{
  if (!ForceBrowser)
    {
  [_tableView reloadData];
    }
  else
    {
  [_browser loadColumnZero];
    }
  [self selectItemAtIndex: [_cell indexOfSelectedItem]];
}

- (void) noteNumberOfItemsChanged
{
  // FIXME: Should only load the additional items
  [self reloadData];
}

- (void) scrollItemAtIndexToTop: (int)index
{
  NSRect rect;
  
  if (!ForceBrowser)
    {
  rect = [_tableView frameOfCellAtColumn: 0 row: index];
  [_tableView scrollPoint: rect.origin]; 
    }
  else
    {  
  NSMatrix *matrix = [_browser matrixInColumn: 0];

  rect = [matrix cellFrameAtRow: index column: 0];
  [matrix scrollPoint: rect.origin];
    }
}

- (void) scrollItemAtIndexToVisible: (int)index
{
  if (!ForceBrowser)
    {
  [_tableView scrollRowToVisible: index];
    }
  else
    {
  NSMatrix *matrix = [_browser matrixInColumn: 0];

  [matrix scrollCellToVisibleAtRow: index column: 0];
    }
}

- (void) selectItemAtIndex: (int)index
{ 
  if (index < 0)
    return;
  
  if (!ForceBrowser)
    {
  if ([_tableView selectedRow] == index || [_tableView numberOfRows] <= index)
    return;
   _localSelection  = YES;
  // Will block the TableDidSelectionChange: action
  [_tableView selectRow: index byExtendingSelection: NO];     
  _localSelection = NO;
    }
  else
    {
  NSMatrix *matrix = [_browser matrixInColumn: 0];
  
  if ([matrix selectedRow] == index || [matrix numberOfRows] <= index)
    return;
  [_browser selectRow: index inColumn: 0];
    }   
}

- (void) deselectItemAtIndex: (int)index
{
  if (!ForceBrowser)
    {
  [_tableView deselectAll: self];
    }
  else
    {
  NSMatrix *matrix = [_browser matrixInColumn: 0];

  [matrix deselectSelectedCell];
    }
}

// Target/Action of Browser
- (void) selectItem: (id)sender
{
  if (_cell)
    {      
      [_cell selectItemAtIndex: [sender selectedRowInColumn: 0]];
      _stopped = YES;
    }
}

// Browser delegate methods
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

// Table view data source methods
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
  return [_cell numberOfItems];
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)tc row: (int)row
{
  return [_cell _stringValueAtIndex: row];
}

// Table view delegate methods
- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
  [self validateSelection];
}

// Key actions methods
- (void) moveUpSelection
{
  if (!ForceBrowser)
    {
  int index = [_tableView selectedRow] - 1;

  if (index > -1 && index < [_tableView numberOfRows])
    {
      _localSelection = YES;
      [_tableView selectRow: index byExtendingSelection: NO];
      [_tableView scrollRowToVisible: index];
      _localSelection = NO;
    }
    }
  else
    {
  int index = [_browser selectedRowInColumn: 0] - 1;

  if (index > -1 && index < [[_browser matrixInColumn: 0] numberOfRows])
    {
      _localSelection = YES;
      [_browser selectRow: index inColumn: 0];
      _localSelection = NO;
    }
    }
}

- (void) moveDownSelection
{
  if (!ForceBrowser)
    { 
  int index = [_tableView selectedRow] + 1;
  
  if (index > -1 && index < [_tableView numberOfRows])
    {
      _localSelection = YES;
      [_tableView selectRow: index byExtendingSelection: NO];
      [_tableView scrollRowToVisible: index];
      _localSelection = NO;
    }
    }
  else
    {
  int index = [_browser selectedRowInColumn: 0] + 1;

  if (index > -1 && index < [[_browser matrixInColumn: 0] numberOfRows])
    {
      _localSelection = YES;
      [_browser selectRow: index inColumn: 0];
      _localSelection = NO;
    }
    }
}

- (void) validateSelection
{
  if (_cell && _localSelection == NO)
    {
      if (!ForceBrowser)
        {
      [_cell selectItemAtIndex: [_tableView selectedRow]];
        }
      else
        {
      [_cell selectItemAtIndex: [_browser selectedRowInColumn: 0]];
	}
      _stopped = YES;
    }
}

@end

// ---

@implementation NSComboBoxCell

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSComboBoxCell class])
    {
      [NSComboBoxCell setVersion: 2];
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
  
  [self _loadButtonCell];

  return self;
}

- (void) dealloc
{
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
  // Method called by GSComboWindow when a selection is done in the table view or 
  // the browser
  
  NSText *textObject = [[[self controlView] window] fieldEditor: YES 
                                                      forObject: self];  
  if ([self usesDataSource])
    {
      if ([self numberOfItems] <= index)
        ; // raise exception
    }
  else
    {
      if ([_popUpList count] <= index)
        ; // raise exception
    }
  
  if (index < 0)
    ; // rais exception

  if (_selectedItem != index)
    {
      _selectedItem = index;
      
      [_popup selectItemAtIndex: index]; 
      // This method call will not create a infinite loop when the index has been 
      // already set by a mouse click because the method is not completed when the 
      // current index is not different from the index parameter
      
      [textObject setString: [self _stringValueAtIndex: _selectedItem]];
      [textObject setSelectedRange: NSMakeRange(0, [[textObject string] length])];

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

- (int) numberOfItems
{
  if (_usesDataSource)
    {
      if (!_dataSource)
        {
	  NSLog(@"%@: A DataSource should be specified", self);
	}
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
    NSLog(@"%@: This method is invalid, this combo box is not set to use a data source", 
      self);
  else
    _dataSource = aSource;
}

- (void) addItemWithObjectValue: (id)object
{
  if (_usesDataSource)
    NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
      self);
  else
    [_popUpList addObject: object];
    
  [self reloadData];
}

- (void) addItemsWithObjectValues: (NSArray *)objects
{
  if (_usesDataSource)
    NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
      self);
  else
    [_popUpList addObjectsFromArray: objects];
    
  [self reloadData];
}

- (void) insertItemWithObjectValue: (id)object atIndex: (int)index
{
  if (_usesDataSource)
    NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
      self);
  else
    [_popUpList insertObject: object atIndex: index];
    
  [self reloadData];
}

- (void) removeItemWithObjectValue: (id)object
{
  if (_usesDataSource)
    NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
      self);
  else
    [_popUpList removeObject: object];
    
  [self reloadData];
}

- (void) removeItemAtIndex: (int)index
{
  if (_usesDataSource)
    NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
      self);
  else
    [_popUpList removeObjectAtIndex: index];
    
  [self reloadData];
}

- (void) removeAllItems
{
  if (_usesDataSource)
    NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
      self);
  else
    [_popUpList removeAllObjects];
    
  [self reloadData];
}

- (void) selectItemWithObjectValue: (id)object
{
 if (_usesDataSource)
    NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
      self);
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
      NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
        self);
      return nil;
    }
  else
    {
      return [_popUpList objectAtIndex: index];
    }
}

- (id) objectValueOfSelectedItem
{
  if (_usesDataSource)
    {
      NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
        self);
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
      NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
        self);
      return 0;
    }
    
  return [_popUpList indexOfObject: object];
}

- (NSArray *)objectValues
{
  if (_usesDataSource)
    {
      NSLog(@"%@: This method is invalid, this combo box is set to use a data source", 
        self);
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
	NSLog(@"%@: A data source should be specified", self);
      else if ([_dataSource respondsToSelector: @selector(comboBox:completedString:)])
        {
	  return [_dataSource comboBox: (NSComboBox *)[self controlView] 
		       completedString: substring];
	}
      else if ([_dataSource respondsToSelector: @selector(comboBoxCell:completedString:)])
        {
	  return [_dataSource comboBoxCell: self completedString: substring];
	}
      else
        {
          unsigned int i;

          for (i = 0; i < [self numberOfItems]; i++)
            {
	      NSString *str = [self _stringValueAtIndex: i];

	      if ([str length] > [substring length] && [str hasPrefix: substring])
	        return str;
            }	
	}
    }
  else
    {
      unsigned int i;

      for (i = 0; i < [_popUpList count]; i++)
        {
	  NSString *str = [[_popUpList objectAtIndex: i] description];

	  if ([str length] > [substring length] && [str hasPrefix: substring])
	    return str;
        }
    }
  
  return substring;
}

- (BOOL)completes { return _completes; }
- (void)setCompletes:(BOOL)completes
{
  _completes = completes;
}

// Inlined methods
#define ButtonWidth 18
#define BorderWidth 2
// the inset border for the top and the bottom of the button

static inline NSRect textCellFrameFromRect(NSRect cellRect)
{
  return NSMakeRect(NSMinX(cellRect),
		    NSMinY(cellRect),
		    NSWidth(cellRect) - ButtonWidth,
		    NSHeight(cellRect));
}

static inline NSRect buttonCellFrameFromRect(NSRect cellRect)
{
  return NSMakeRect(NSMaxX(cellRect) - ButtonWidth,
		    NSMinY(cellRect) + BorderWidth,
		    ButtonWidth,
		    NSHeight(cellRect) - (BorderWidth * 2.0));
}

// Overridden
+ (BOOL) prefersTrackingUntilMouseUp
{
  return YES; 
  /* Needed to have the clickability of the button take in account when the tracking happens.
     This method is call by the NSControl -mouseDown: method with the code :
     [_cell trackMouse: e
		inRect: _bounds
	        ofView: self
          untilMouseUp: [[_cell class] prefersTrackingUntilMouseUp]] */
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
  // FIX ME: Is this test case below with the method call really needed ?
  if ([GSCurrentContext() isDrawingToScreen]) 
    {
      [super drawWithFrame: textCellFrameFromRect(cellFrame)
	            inView: controlView];
      [_buttonCell drawWithFrame: buttonCellFrameFromRect(cellFrame)
		          inView: controlView];
    }
  else
    {
      [super drawWithFrame: cellFrame inView: controlView];
    }
    
  _lastValidFrame = cellFrame; // used by GSComboWindow to appear in the right position
}

- (void) highlight: (BOOL)flag
	 withFrame: (NSRect)cellFrame
	    inView: (NSView *)controlView
{
  // FIX ME: Is this test case below with the method call really needed ?
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
    {
      [super highlight: flag withFrame: cellFrame inView: controlView];
    }
}

- (BOOL) trackMouse: (NSEvent *)theEvent 
	     inRect: (NSRect)cellFrame
	     ofView: (NSView *)controlView 
       untilMouseUp: (BOOL)flag
{
  NSWindow *cvWindow = [controlView window];
  NSPoint point;
  BOOL isFlipped = [controlView isFlipped];
  BOOL clicked = NO;
  
  // Should this be set by NSActionCell ?
  if (_control_view != controlView)
    _control_view = controlView;

  point = [controlView convertPoint: [theEvent locationInWindow]
			   fromView: nil];

  if (!NSMouseInRect(point, cellFrame, isFlipped))
    return NO; 
  else if ([theEvent type] == NSLeftMouseDown)
    {
      if (NSMouseInRect(point, textCellFrameFromRect(cellFrame), isFlipped))
	{
	  return YES;// continue
	}
      else if (NSMouseInRect(point, buttonCellFrameFromRect(cellFrame), isFlipped))
 	{
          [controlView lockFocus];
          [_buttonCell highlight: YES withFrame: buttonCellFrameFromRect(cellFrame) inView: controlView];
	  [controlView unlockFocus];
	  [cvWindow flushWindow];
	  
          clicked = [_buttonCell trackMouse: theEvent 
	                             inRect: buttonCellFrameFromRect(cellFrame)
	                             ofView: controlView
		  	       untilMouseUp: NO];

          /* We can do the call below but it is already done by the target/action we have set for the button cell
	  if (clicked)
	    [self _didClickWithinButton: self]; // not to be used */
	  	       
	  [controlView lockFocus];
          [_buttonCell highlight: NO withFrame: buttonCellFrameFromRect(cellFrame) inView: controlView];
	  [controlView unlockFocus];
	  [cvWindow flushWindow];
	  
	  return NO;
        }
    }
    
  return NO;
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

- (id) initWithCoder: (NSCoder *)aDecoder
{
  self = [super initWithCoder: aDecoder];
  
  if ([aDecoder allowsKeyedCoding])
    {
      //id delegate = [aDecoder decodeObjectForKey: @"NSDelegate"];
      // FIXME: This does not match the way GNUstep currently implements
      // the list of popup items.
      //id table = [aDecoder decodeObjectForKey: @"NSTableView"];

      if ([aDecoder containsValueForKey: @"NSHasVerticalScroller"])
        {
	  [self setHasVerticalScroller: [aDecoder decodeBoolForKey: 
						      @"NSHasVerticalScroller"]];
	}
      if ([aDecoder containsValueForKey: @"NSVisibleItemCount"])
        {
	  [self setNumberOfVisibleItems: [aDecoder decodeIntForKey: 
						       @"NSVisibleItemCount"]];
	}
    }
  else
    {
      BOOL dummy;
      id previouslyEncodedButton;
      
      if ([aDecoder versionForClassName: @"NSComboBoxCell"] < 2)
        [aDecoder decodeValueOfObjCType: @encode(id) at: &previouslyEncodedButton];
      // In previous version we decode _buttonCell, we just discard the decoded value here
      
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_popUpList];
      RETAIN(_popUpList);
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_usesDataSource];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasVerticalScroller];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_completes];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &dummy];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_visibleItems];
      [aDecoder decodeValueOfObjCType: @encode(NSSize) at: &_intercellSpacing];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_itemHeight];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_selectedItem];

      if (_usesDataSource == YES)
	[self setDataSource: [aDecoder decodeObject]];      
    }
  
  [self _loadButtonCell];

  return self;
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
  
  [nc addObserver: self 
         selector: @selector(textDidChange:)
	     name: NSTextDidChangeNotification 
	   object: textObj];
  [nc addObserver: self 
         selector: @selector(textViewDidChangeSelection:)
	     name: NSTextViewDidChangeSelectionNotification 
	   object: textObj];
	  
  // This method is called when the cell obtains the focus;
  // don't know why the next method editWithFrame: is not called
}

- (void) editWithFrame: (NSRect)frame
                inView: (NSView *)controlView
	        editor: (NSText *)textObj 
	      delegate: (id)delegate 
	         event: (NSEvent *)theEvent
{
  [super editWithFrame: textCellFrameFromRect(frame)
                inView: controlView
                editor: textObj
              delegate: delegate
                 event: theEvent];
  
  /*
  [nc addObserver: self 
         selector: @selector(textDidChange:)
	     name: NSTextDidChangeNotification 
	   object: textObj];
  [nc addObserver: self 
         selector: @selector(textViewDidChangeSelection:)
	     name: NSTextViewDidChangeSelectionNotification 
	   object: textObj]; */
}

- (void) endEditing: (NSText *)editor
{
  [super endEditing: editor];
  [nc removeObserver: self name: NSTextDidChangeNotification object: editor];
  [nc removeObserver: self 
                name: NSTextViewDidChangeSelectionNotification 
	      object: editor];
}

- (void) textViewDidChangeSelection: (NSNotification *)notification
{
  _prevSelectedRange = [[[notification userInfo] 
    objectForKey: @"NSOldSelectedCharacterRange"] rangeValue];
}

- (void) textDidChange: (NSNotification *)notification
{
  NSText *textObject = [notification object];

  if ([self completes])
    {
      NSString *myString = [[textObject string] copy];
      NSString *more;
      unsigned int myStringLength = [myString length];
      unsigned int location, length;
      NSRange selectedRange = [textObject selectedRange];
      
      if (myStringLength != 0
        && selectedRange.location == myStringLength
        && _prevSelectedRange.location < selectedRange.location)
        {
          more = [self completedString: myString];
          if (![more isEqualToString: myString])
            {
	      [textObject setString: more];
	      location = myStringLength;
              length = [more length] - location;
	      [textObject setSelectedRange: NSMakeRange(location, length)];
	    }
        }
    }
}

@end

@implementation NSComboBoxCell (GNUstepPrivate)

- (NSString *) _stringValueAtIndex: (int)index
{
  if (!_usesDataSource)
    {
      return [[self itemObjectValueAtIndex: index] description];
    }
  else
    {
      if (!_dataSource)
        {
	  NSLog(@"%@: No data source currently specified", self);
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

- (void) _performClickWithFrame: (NSRect)cellFrame 
                         inView: (NSView *)controlView
{
  NSWindow *cvWindow = [controlView window];

  [controlView lockFocus];
  [_buttonCell highlight: YES 
	       withFrame: buttonCellFrameFromRect(cellFrame) 
	          inView: controlView];
  [controlView unlockFocus];
  [cvWindow flushWindow];

  [self _didClickWithinButton: self];
  
  [controlView lockFocus];
  [_buttonCell highlight: NO 
	       withFrame: buttonCellFrameFromRect(cellFrame) 
	          inView: controlView];
  [controlView unlockFocus];
  [cvWindow flushWindow];

}

- (void) _didClickWithinButton: (id)sender
{
  NSView *controlView = [self controlView];
  
  if ((_cell.is_disabled) || (controlView == nil))
    return;

  [nc postNotificationName: NSComboBoxWillPopUpNotification 
                    object: controlView 
		  userInfo: nil];
  
  _popup = [self _popUp];
  [_popup popUpForComboBoxCell: self];
  _popup = nil;

  [nc postNotificationName: NSComboBoxWillDismissNotification
                    object: controlView
                  userInfo: nil];
}

- (BOOL) _isWantedEvent: (NSEvent *)event
{
  NSPoint loc;
  NSWindow *window = [event window];
  NSView *controlView = [self controlView];
  
  if (window == [[self controlView] window])
    {
      loc = [event locationInWindow];
      loc = [controlView convertPoint: loc fromView: nil];
      return NSMouseInRect(loc, [self _textCellFrame], [controlView isFlipped]);
    }
  else
    {
      return NO;
    }
}

- (GSComboWindow *) _popUp
{
  return [GSComboWindow defaultPopUp];
}

- (NSRect) _textCellFrame
{
  return textCellFrameFromRect(_lastValidFrame);
}

- (void) _setSelectedItem: (int)index
{
  _selectedItem = index;
}

- (void) _loadButtonCell
{
  if (!ForceArrowIcon)
    {
      _buttonCell = [[NSButtonCell alloc] initImageCell: 
        [NSImage imageNamed: @"NSComboBoxEllipsis"]];
    }
  else
    {
       _buttonCell = [[NSButtonCell alloc] initImageCell: 
        [NSImage imageNamed: @"NSComboArrow"]];
    }
    
  [_buttonCell setImagePosition: NSImageOnly];
  [_buttonCell setButtonType: NSMomentaryPushButton];
  [_buttonCell setHighlightsBy: NSPushInCellMask];
  [_buttonCell setBordered: YES];
  [_buttonCell setTarget: self];
  [_buttonCell setAction: @selector(_didClickWithinButton:)];
}

@end
