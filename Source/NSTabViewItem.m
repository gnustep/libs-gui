/** <title>NSTabViewItem</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "AppKit/NSColor.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSTabViewItem.h"
#include "AppKit/PSOperators.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSAttributedString.h"

@implementation NSTabViewItem
- (id) initWithIdentifier:(id)identifier
{
  [super init];

  ASSIGN(_ident, identifier);
  _state = NSBackgroundTab;

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_ident);
  RELEASE(_label);
  RELEASE(_view);
  RELEASE(_color);
  [super dealloc];
}

// Set identifier.

- (void)setIdentifier:(id)identifier
{
  ASSIGN(_ident, identifier);
}

- (id)identifier
{
  return _ident;
}

// Set label for item.

- (void)setLabel:(NSString *)label
{
  ASSIGN(_label, label);
}

- (NSString *)label
{
  return _label;
}

- (NSSize)sizeOfLabel:(BOOL)shouldTruncateLabel
{
  NSDictionary *  attr = [[NSDictionary alloc] initWithObjectsAndKeys: 
			       [_tabview font], NSFontAttributeName,
			       nil];
  NSString *string;
  NSSize rSize;

  if (shouldTruncateLabel) 
    {
      string = [self _truncatedLabel];
    } 
  else 
    {
	string = _label;
    }

  rSize = [string sizeWithAttributes: attr];
  RELEASE(attr);
  return rSize;
}

// Set view to display when item is clicked.

- (void)setView:(NSView *)view
{
  ASSIGN(_view, view);
}

- (NSView *)view
{
  return _view;
}

// Set color of tab surface.

- (void)setColor:(NSColor *)color
{
  ASSIGN(_color, color);
}

- (NSColor *)color
{
  return _color;
}

// tab state

- (NSTabState)tabState
{
  return _state;
}


// Tab view, this is the "super" view.

- (NSTabView *)tabView
{
  return _tabview;
}

// First responder.

- (void)setInitialFirstResponder:(NSView *)view
{
  // We don't retain this.  
  _first_responder = view;
}

- (id)initialFirstResponder
{
  return _first_responder;
}

// Draw item.

- (void)drawLabel:(BOOL)shouldTruncateLabel
	   inRect:(NSRect)tabRect
{
  NSGraphicsContext     *ctxt = GSCurrentContext();
//  NSRect lRect;
  NSRect fRect;
  NSDictionary *attr;
  NSString *string;

  if (shouldTruncateLabel) 
    {
      string = [self _truncatedLabel];
    } 
  else 
    {
	string = _label;
    }

  _rect = tabRect;

  DPSgsave(ctxt);

  fRect = tabRect;

  if (_state == NSSelectedTab)
    {
      fRect.origin.y -= 1;
      fRect.size.height += 1;
      [[NSColor controlBackgroundColor] set];
      NSRectFill(fRect);
    }
  else if (_state == NSBackgroundTab)
    {
      [[NSColor controlBackgroundColor] set];
      NSRectFill(fRect);
    }
  else
    {
      [[NSColor controlBackgroundColor] set];
    }

  attr = [[NSDictionary alloc] initWithObjectsAndKeys: 
			       [_tabview font], NSFontAttributeName,
			       [NSColor blackColor], NSForegroundColorAttributeName,
			       nil];

  // For some unclear reason, somehow connected with clipping,
  // drawInRect does not work here. But drawAtPoint works fine.
  [string drawAtPoint: NSMakePoint(tabRect.origin.x, NSMaxY(tabRect)) 
	  withAttributes: attr];
//  lRect = tabRect;
//  lRect.origin.y += 3;
//  [_label drawInRect: lRect withAttributes: attr];
  RELEASE(attr);

  DPSgrestore(ctxt);
}

// NSCoding protocol.

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject:_ident];
  [aCoder encodeObject:_label];
  [aCoder encodeObject:_view];
  [aCoder encodeObject:_color];
  [aCoder encodeValueOfObjCType: @encode(NSTabState) at: &_state];
  [aCoder encodeObject:_first_responder];
  [aCoder encodeObject:_tabview];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_ident];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_label];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_view];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_color];
  [aDecoder decodeValueOfObjCType: @encode(NSTabState) at:&_state];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_first_responder];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_tabview];

  return self;
}
@end

@implementation NSTabViewItem (GNUstep)

// Non spec

- (NSRect) _tabRect
{
  return _rect;
}

- (void)_setTabState:(NSTabState)tabState
{
  _state = tabState;
}

- (void)_setTabView:(NSTabView *)tabView
{
  _tabview = tabView;
}

- (NSString*)_truncatedLabel
{
  // FIXME: What is the algo to truncate?
  return _label;
}

@end
