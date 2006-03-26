/* 
   NSSearchFieldCell.h
 
   Text field cell class for text search
 
   Copyright (C) 2004 Free Software Foundation, Inc.
 
   Author: H. Nikolaus Schaller <hns@computer.org>
   Date: Dec 2004
   Author: Fred Kiefer <fredkiefer@gmx.de>
   Date: Mar 2006
 
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSMenu.h>
#include "AppKit/NSMenuView.h"
#include <AppKit/NSSearchFieldCell.h>
#include "AppKit/NSWindow.h"

@interface NSSearchFieldCell (Private)

- (NSMenu *) _buildTemplate;
- (void) _openPopup: (id)sender;
- (void) _clearSearches: (id)sender;
- (void) _loadSearches;
- (void) _saveSearches;

@end /* NSSearchFieldCell Private */


@implementation NSSearchFieldCell

- (id) initTextCell:(NSString *)aString
{
  self = [super initTextCell: aString];
  if (self)
    {
      NSButtonCell *c;
      NSMenu *template;

      c = [[NSButtonCell alloc] initImageCell: nil];
      [self setCancelButtonCell: c];
      RELEASE(c);
      [self resetCancelButtonCell];

      c = [[NSButtonCell alloc] initImageCell: nil];
      [self setSearchButtonCell: c];
      RELEASE(c);
      [self resetSearchButtonCell];

      template = [self _buildTemplate];
      [self setSearchMenuTemplate: template];
      RELEASE(template);

      //_recent_searches = nil;
      //_recents_autosave_name = nil;
      _max_recents = 10;
    }

  return self;
}

- (void) dealloc
{
  RELEASE(_cancel_button_cell);
  RELEASE(_search_button_cell);
  RELEASE(_recent_searches);
  RELEASE(_recents_autosave_name);
  RELEASE(_menu_template);

  [super dealloc];
}

- (id) copyWithZone:(NSZone *) zone;
{
  NSSearchFieldCell *c = [super copyWithZone: zone];

  c->_cancel_button_cell = [_cancel_button_cell copyWithZone: zone];
  c->_search_button_cell = [_search_button_cell copyWithZone: zone];
  c->_recent_searches = [_recent_searches copyWithZone: zone];
  c->_recents_autosave_name = [_recents_autosave_name copyWithZone: zone];
  c->_menu_template = [_menu_template copyWithZone: zone];

  return c;
}

- (BOOL) isOpaque
{
  // only if all components are opaque
  return [super isOpaque] && [_cancel_button_cell isOpaque] && 
      [_search_button_cell isOpaque];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  [_search_button_cell drawWithFrame: [self searchButtonRectForBounds: cellFrame] 
		       inView: controlView];
  [super drawWithFrame: [self searchTextRectForBounds: cellFrame] 
	 inView: controlView];
  [_cancel_button_cell drawWithFrame: [self cancelButtonRectForBounds: cellFrame] 
		       inView: controlView];
}

- (BOOL) sendsWholeSearchString
{ 
  return _sends_whole_search_string; 
}

- (void) setSendsWholeSearchString: (BOOL)flag
{
  _sends_whole_search_string = flag;
}

- (BOOL) sendsSearchStringImmediately
{ 
  return _sends_search_string_immediatly; 
}

- (void) setSendsSearchStringImmediately: (BOOL)flag
{
  _sends_search_string_immediatly = flag;
}

- (int) maximumRecents
{ 
  return _max_recents;
}

- (void) setMaximumRecents: (int)max
{
  if (max > 254)
    {
      max = 254;
    }
  else if (max < 0)
    {
      max = 10;
    }

  _max_recents = max;
}

- (NSArray *) recentSearches
{
  return _recent_searches;
}

- (NSString *) recentsAutosaveName
{
  return _recents_autosave_name; 
}

- (void) setRecentSearches: (NSArray *)searches
{
  int max;

  max = [self maximumRecents];
  if ([searches count] > max)
    {
      id buffer[max];

      [searches getObjects: buffer range: NSMakeRange(0, max)];
      searches = [NSArray arrayWithObjects: buffer count: max];
    }
  ASSIGN(_recent_searches, searches);
}
 
- (void) setRecentsAutosaveName: (NSString *)name
{
  ASSIGN(_recents_autosave_name, name);
}

- (NSMenu *) searchMenuTemplate
{
  return _menu_template;
}

- (void) setSearchMenuTemplate: (NSMenu *)menu
{
  ASSIGN(_menu_template, menu);
}

- (NSButtonCell *) cancelButtonCell
{
  return _cancel_button_cell;
}

- (void) setCancelButtonCell: (NSButtonCell *)cell
{
  ASSIGN(_cancel_button_cell, cell);
}

- (NSButtonCell *) searchButtonCell
{
  return _search_button_cell;
}

- (void) setSearchButtonCell: (NSButtonCell *)cell
{ 
  ASSIGN(_search_button_cell, cell);
}

- (void) resetCancelButtonCell
{
  NSButtonCell *c;
  
  c = [self cancelButtonCell];
  // configure the button
  [c setButtonType: NSMomentaryChangeButton];
  [c setBezelStyle: NSRegularSquareBezelStyle];
  [c setBordered: NO];
  [c setBezeled: NO];
  [c setEditable: NO];
  [c setImagePosition: NSImageOnly];
  [c setImage: [NSImage imageNamed: @"GSStop"]];
  [c setAction: @selector(delete:)];
  [c setTarget: nil];
  [c setKeyEquivalent: @"\e"];
}

- (void) resetSearchButtonCell
{
  NSButtonCell *c;

  c = [self searchButtonCell];
  // configure the button
  [c setButtonType: NSMomentaryChangeButton];
  [c setBezelStyle: NSRegularSquareBezelStyle];
  [c setBordered: NO];
  [c setBezeled: NO];
  [c setEditable: NO];
  [c setImagePosition: NSImageOnly];
  [c setImage: [NSImage imageNamed: @"GSSearch"]];
  [c setAction: [self action]];
  [c setTarget: [self target]];
  [c setKeyEquivalent: @"\r"];
}

#define ICON_WIDTH	16

- (NSRect) cancelButtonRectForBounds: (NSRect)rect
{
  NSRect part, clear;
	
  NSDivideRect(rect, &clear, &part, ICON_WIDTH, NSMaxXEdge);
  return clear;
}

- (NSRect) searchTextRectForBounds: (NSRect)rect
{
  NSRect search, text, clear, part;

  if (!_search_button_cell)
    {
      // nothing to split off
      part = rect;
    }
  else
  {
    NSDivideRect(rect, &search, &part, ICON_WIDTH, NSMinXEdge);
  }

  if(!_cancel_button_cell)
    {
      // nothing to split off
      text = part;
    }
  else
    {
      NSDivideRect(part, &clear, &text, ICON_WIDTH, NSMaxXEdge);
    }

  return text;
}

- (NSRect) searchButtonRectForBounds: (NSRect)rect;
{
  NSRect search, part;
  
  NSDivideRect(rect, &search, &part, ICON_WIDTH, NSMinXEdge);
  return search;
}

- (void) editWithFrame: (NSRect)aRect
		inView: (NSView*)controlView
		editor: (NSText*)textObject
	      delegate: (id)anObject
		 event: (NSEvent*)theEvent
{
  // constrain to visible text area
  [super editWithFrame: [self searchTextRectForBounds: aRect]
	        inView: controlView
	        editor: textObject
	      delegate: anObject
	         event: theEvent];
  [[NSNotificationCenter defaultCenter] 
      addObserver: self 
         selector: @selector(textDidChange:)
             name: NSTextDidChangeNotification 
           object: textObject];

}

- (void) endEditing: (NSText *)editor
{
  [super endEditing: editor];
  [[NSNotificationCenter defaultCenter] 
      removeObserver: self 
                name: NSTextDidChangeNotification 
              object: editor];
}

- (void) selectWithFrame: (NSRect)aRect
		  inView: (NSView*)controlView
		  editor: (NSText*)textObject
		delegate: (id)anObject
		   start: (int)selStart	 
		  length: (int)selLength
{ 
  // constrain to visible text area
  [super selectWithFrame: [self searchTextRectForBounds: aRect]
	          inView: controlView
	          editor: textObject
	        delegate: anObject
	           start: selStart
	          length: selLength];
}

- (BOOL) trackMouse: (NSEvent *)event 
	     inRect: (NSRect)cellFrame 
	     ofView: (NSView *)controlView 
       untilMouseUp: (BOOL)untilMouseUp
{
  NSRect rect;
  NSPoint thePoint;
  NSPoint location = [event locationInWindow];

  thePoint = [controlView convertPoint: location fromView: nil];

  // check if we are within the search/stop buttons
  rect = [self searchButtonRectForBounds: cellFrame];
  if ([controlView mouse: thePoint inRect: rect])
    {
      return [[self searchButtonCell] trackMouse: event 
				      inRect: rect 
				      ofView: controlView 
				      untilMouseUp: untilMouseUp];
    }

  rect = [self cancelButtonRectForBounds: cellFrame];
  if ([controlView mouse: thePoint inRect: rect])
    {
      return [[self cancelButtonCell] trackMouse: event 
				      inRect: rect 
				      ofView: controlView 
				      untilMouseUp: untilMouseUp];
    }

  return [super trackMouse: event 
		inRect: [self searchTextRectForBounds: cellFrame]
		ofView: controlView 
		untilMouseUp: untilMouseUp];
}

- (void) textDidChange: (NSNotification *)notification
{ 
  NSText *textObject;

  // make textChanged send action (unless disabled)
  if (_sends_whole_search_string)
    {
      // ignore
      return;
    }

  textObject = [notification object];
  // copy the current NSTextEdit string so that it can be read from the NSSearchFieldCell!
  [self setStringValue: [textObject string]];
  [[self searchButtonCell] performClickWithFrame: 
			       [self searchButtonRectForBounds: [_control_view bounds]] 
			   inView: _control_view];
}
//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeObject: _search_button_cell];
  [aCoder encodeObject: _cancel_button_cell];
  [aCoder encodeObject: _recents_autosave_name];
  [aCoder encodeValueOfObjCType: @encode(BOOL)
			     at: &_sends_whole_search_string];
  [aCoder encodeValueOfObjCType: @encode(unsigned int)
			     at: &_max_recents];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];
  
  if ([aDecoder allowsKeyedCoding])
    {
      [self setSearchButtonCell: [aDecoder decodeObjectForKey: @"NSSearchButtonCell"]];
      [self setCancelButtonCell: [aDecoder decodeObjectForKey: @"NSCancelButtonCell"]];
      [self setRecentsAutosaveName: [aDecoder decodeObjectForKey: @"NSRecentsAutosaveName"]];
      [self setSendsWholeSearchString: [aDecoder decodeBoolForKey: @"NSSendsWholeSearchString"]];
      [self setMaximumRecents: [aDecoder decodeIntForKey: @"NSMaximumRecents"]];
    }
  else
    {
      [self setSearchButtonCell: [aDecoder decodeObject]];
      [self setCancelButtonCell: [aDecoder decodeObject]];
      [self setRecentsAutosaveName: [aDecoder decodeObject]];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_sends_whole_search_string];
      [aDecoder decodeValueOfObjCType: @encode(unsigned int) at: &_max_recents];
    }

  return self;
}

@end /* NSSearchFieldCell */


@implementation NSSearchFieldCell (Private)

/* Set up a default template
 */
- (NSMenu *) _buildTemplate
{
  NSMenu *template;
  NSMenuItem *item;

  template = [[NSMenu alloc] init];
  
  item = [[NSMenuItem alloc] initWithTitle: @"Recent searches"
			     action: NULL
			     keyEquivalent: @""];
  [item setTag: NSSearchFieldRecentsTitleMenuItemTag];
  [template addItem: item];
  RELEASE(item);
  
  item = [[NSMenuItem alloc] initWithTitle: @"Recent search item"
			     action: @selector(search:)
			     keyEquivalent: @""];
  [item setTag: NSSearchFieldRecentsMenuItemTag];
  [template addItem: item];
  RELEASE(item);
  
  item = [[NSMenuItem alloc] initWithTitle: @"Clear recent searches"
			     action: @selector(_clearSearches:)
			     keyEquivalent: @""];
  [item setTag: NSSearchFieldClearRecentsMenuItemTag];
  [item setTarget: self];
  [template addItem: item];
  
  RELEASE(item);
  item = [[NSMenuItem alloc] initWithTitle: @"No recent searches"
			     action: NULL
			     keyEquivalent: @""];
  [item setTag: NSSearchFieldNoRecentsMenuItemTag];
  [template addItem: item];
  RELEASE(item);
  
  return template;
}

- (void) _openPopup: (id)sender
{
  NSMenu *template;
  NSMenu *popupmenu;
  NSMenuView *mr;
  NSWindow *cvWin;
  NSRect cellFrame;
  NSRect textRect;
  int i;

  template = [self searchMenuTemplate];
  popupmenu = [[NSMenu alloc] init];

  // Fill the popup menu 
  for (i = 0; i < [template numberOfItems]; i++)
    {
      int tag;
      NSMenuItem *item;
      int count = [_recent_searches count];

      item = (NSMenuItem*)[template itemAtIndex: i];
      tag = [item tag];
      if ((tag == NSSearchFieldRecentsTitleMenuItemTag) || 
	  (tag == NSSearchFieldClearRecentsMenuItemTag) ||
	  ((tag == NSSearchFieldRecentsMenuItemTag) && ((count == 0))))
        { 
	  NSMenuItem *copy;
	  
	  copy = [item copy];
	  [popupmenu addItem: copy];
	  RELEASE(copy);
	}
      else if (tag == NSSearchFieldRecentsMenuItemTag)
        {
	  int j;

	  for (j = 0; j < count; j++)
	    {
	      [popupmenu addItemWithTitle: [_recent_searches objectAtIndex: j]
			 action: [item action]
			 keyEquivalent: [item keyEquivalent]];
	    }
	}
    } 

  // Prepare to display the popup
  cvWin = [_control_view window];
  cellFrame = [_control_view bounds];
  textRect = [self searchTextRectForBounds: cellFrame] ;
  mr = [popupmenu menuRepresentation];

  // Ask the MenuView to attach the menu to this rect
  [mr setWindowFrameForAttachingToRect: textRect
      onScreen: [cvWin screen]
      preferredEdge: NSMinYEdge
      popUpSelectedItem: -1];
  
  // Last, display the window
  [[mr window] orderFrontRegardless];

  AUTORELEASE(popupmenu);
}

- (void) _clearSearches: (id)sender
{
  [self setRecentSearches: [NSArray array]];
}

- (void) _loadSearches
{
  NSArray *list;
  NSString *name = [self recentsAutosaveName];

  list = [[NSUserDefaults standardUserDefaults] 
	     stringArrayForKey: name];
  [self setRecentSearches: list];
}

- (void) _saveSearches
{
  NSArray *list = [self recentSearches];
  NSString *name = [self recentsAutosaveName];

  [[NSUserDefaults standardUserDefaults] 
      setObject: list forKey: name];
}

@end /* NSSearchFieldCell Private */
