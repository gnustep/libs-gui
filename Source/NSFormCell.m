/** <title>NSFormCell</title>

   <abstract>The cell class for the NSForm control</abstract>

   Copyright (C) 1996, 1999 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: November 1999
   
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

#include "gnustep/gui/config.h"
#include <Foundation/NSNotification.h>
#include "AppKit/NSColor.h"
#include "AppKit/NSFormCell.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSTextFieldCell.h"

static NSColor	*shadowCol;

@interface NSFormCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n;
@end

@implementation	NSFormCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n
{
  ASSIGN(shadowCol, [NSColor controlDarkShadowColor]);
}
@end

@implementation NSFormCell
+ (void) initialize
{
  if (self == [NSFormCell class])
    {
      [self setVersion: 1];
      [[NSNotificationCenter defaultCenter] 
	addObserver: self
	selector: @selector(_systemColorsChanged:)
	name: NSSystemColorsDidChangeNotification
	object: nil];
      [self _systemColorsChanged: nil];
    }
}

/* The title attributes are those inherited from the NSActionCell class. */
- init
{
  return [self initTextCell: @"Field:"];
}

- initTextCell: (NSString *)aString
{
  self = [super initTextCell: @""];
  _cell.is_bezeled = YES;
  _cell.is_editable = YES;
  [self setAlignment: NSLeftTextAlignment];
  _titleCell = [[NSCell alloc] initTextCell: aString];
  [_titleCell setAlignment: NSRightTextAlignment];
  _formcell_auto_title_width = YES;
  _displayedTitleWidth = -1;
  return self;
}

- (void)dealloc
{
  RELEASE(_titleCell);
  [super dealloc];
}

- (BOOL)isOpaque
{
  return [_titleCell isOpaque] && [super isOpaque];
}

- (void)setAttributedTitle:(NSAttributedString *)anAttributedString
{
  [_titleCell setAttributedStringValue: anAttributedString];
  if (_formcell_auto_title_width)
    {
      // Invalidates title width 
      _displayedTitleWidth = -1;
      // Update the control(s)
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: _NSFormCellDidChangeTitleWidthNotification
	object: self];
    }
}

- (void)setTitle: (NSString*)aString
{
  [_titleCell setStringValue: aString];
  if (_formcell_auto_title_width)
    {
      // Invalidates title width 
      _displayedTitleWidth = -1;
      // Update the control(s)
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: _NSFormCellDidChangeTitleWidthNotification
	object: self];
    }
}

- (void)setTitleWithMnemonic:(NSString *)titleWithAmpersand
{
  [_titleCell setTitleWithMnemonic: titleWithAmpersand];
  if (_formcell_auto_title_width)
    {
      // Invalidates title width 
      _displayedTitleWidth = -1;
      // Update the control(s)
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: _NSFormCellDidChangeTitleWidthNotification
	object: self];
    }
}

- (void)setTitleAlignment:(NSTextAlignment)mode
{
  [_titleCell setAlignment: mode];
}

- (void)setTitleFont: (NSFont*)fontObject
{
  [_titleCell setFont: fontObject];
  if (_formcell_auto_title_width)
    {
      // Invalidates title width 
      _displayedTitleWidth = -1;
      // Update the control(s)
      [[NSNotificationCenter defaultCenter] 
	postNotificationName: _NSFormCellDidChangeTitleWidthNotification
	object: self];
    }
}

- (void)setTitleWidth: (float)width
{
  if (width >= 0)
    {
      _formcell_auto_title_width = NO;
      _displayedTitleWidth = width;
    }
  else 
    {
      _formcell_auto_title_width = YES;
      _displayedTitleWidth = -1;
    }
  // TODO: Don't updated the control if nothing changed.

  // Update the control(s)
  [[NSNotificationCenter defaultCenter] 
    postNotificationName: _NSFormCellDidChangeTitleWidthNotification
    object: self];
}

- (NSAttributedString *)attributedTitle
{
  return [_titleCell attributedStringValue];
}

- (NSString*)title
{
  return [_titleCell stringValue];
}

- (NSTextAlignment)titleAlignment
{
  return [_titleCell alignment];
}

- (NSFont*)titleFont
{
  return [_titleCell font];
}

//
// Warning: this method returns the width of the title; the width the
// title would have if the cell was the only cell in the form.  This
// is used by NSForm to align all the cells in its form.  This is to
// say that this title width is *not* what you are going to see on the
// screen if more than one cell is present.  Setting a titleWidth
// manually with setTitleWidth: disables any alignment with other
// cells.
//
- (float)titleWidth
{
  if (_formcell_auto_title_width == NO)
    return _displayedTitleWidth;
  else
    {
      NSSize titleSize = [_titleCell cellSize];
      return titleSize.width;
    }
}

- (float)titleWidth: (NSSize)aSize
{
  if (_formcell_auto_title_width == NO)
    return _displayedTitleWidth;
  else
    {
      NSSize titleSize = [_titleCell cellSize];

      if (aSize.width > titleSize.width)
	return titleSize.width;
      else
	return aSize.width;
    }
}

// Updates the title width.  The width of aRect is the new title width
// to display.  Invoked by NSForm to align the editable parts of the
// cells.
- (void) calcDrawInfo: (NSRect)aRect
{
  if (_formcell_auto_title_width == NO)
    return;
  
  _displayedTitleWidth = aRect.size.width;
}


- (NSSize)cellSize
{
  NSSize returnedSize;
  NSSize titleSize = [_titleCell cellSize];
  NSSize textSize;
  
  if (_contents != nil)
    textSize = [super cellSize];
  else
    {
      ASSIGN (_contents, @"Minimum");
      _cell.contents_is_attributed_string = NO;
      textSize = [super cellSize];
      DESTROY (_contents);
    }

  returnedSize.width = titleSize.width + 3 + textSize.width;

  if (titleSize.height > textSize.height)
    returnedSize.height = titleSize.height;
  else
    returnedSize.height = textSize.height; 
  
  return returnedSize;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  // Safety check
  if (_displayedTitleWidth == -1)
    _displayedTitleWidth = [self titleWidth];

  theRect.origin.x   += _displayedTitleWidth + 3;
  theRect.size.width -= _displayedTitleWidth + 3;
  
  return [super drawingRectForBounds: theRect];
}

- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  NSRect titleFrame = cellFrame;
  NSRect borderedFrame = cellFrame;

  // Save last view drawn to
  if (_control_view != controlView)
    _control_view = controlView;
  
  // do nothing if cell's frame rect is zero
  if (NSIsEmptyRect(cellFrame))
    return;

  // Safety check
  if (_displayedTitleWidth == -1)
    _displayedTitleWidth = [self titleWidth];

  //
  // Draw title
  //
  titleFrame.size.width = _displayedTitleWidth;
  [_titleCell drawWithFrame: titleFrame inView: controlView];

  //
  // Leave unfilled the space between titlecell and editable text.
  // 
  
  //
  // Draw border
  //
  borderedFrame.origin.x   += _displayedTitleWidth + 3;
  borderedFrame.size.width -= _displayedTitleWidth + 3;

  if (NSIsEmptyRect(borderedFrame))
    return;
  
  if (_cell.is_bordered)
    {
      [shadowCol set];
      NSFrameRect(borderedFrame);
    }
  else if (_cell.is_bezeled)
    {
      NSDrawWhiteBezel(borderedFrame, NSZeroRect);
    }

  //
  // Draw interior
  //
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

/*
 * Copying
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSFormCell *c = (NSFormCell *)[super copyWithZone:zone];
  
  /* We need to copy the title cell (as opposed to simply copying the
     pointer to it), otherwise if eg we change the string value of the
     title cell of the copied cell, the string value of the title cell
     of the original cell would be changed too ! */
  c->_titleCell = [_titleCell copyWithZone: zone];
  
  return c;
}


- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL tmp;

  [super encodeWithCoder: aCoder];

  tmp = _formcell_auto_title_width;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tmp];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_displayedTitleWidth];
  [aCoder encodeObject: _titleCell];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  BOOL tmp;

  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
  _formcell_auto_title_width = tmp;
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_displayedTitleWidth];
  [aDecoder decodeValueOfObjCType: @encode(id)
	    at: &_titleCell];
  return self;
}

@end

