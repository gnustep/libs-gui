/* 
   NSFormCell.m

   The cell class for the NSForm control

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

#include <gnustep/gui/config.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSFormCell.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSTextFieldCell.h>

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
  _cell.is_bordered = NO;
  _cell.text_align = NSLeftTextAlignment;
  _cell.is_editable = YES;
  _titleCell = [[NSCell alloc] initTextCell: aString];
  [_titleCell setBordered: NO];
  [_titleCell setBezeled: NO];
  [_titleCell setAlignment: NSRightTextAlignment];
  _formcell_auto_title_width = YES;
  _titleWidth = [[self titleFont] widthOfString: aString];
  return self;
}

- (void)dealloc
{
  [_titleCell release];
  [super dealloc];
}

- (BOOL)isOpaque
{
  return [_titleCell isOpaque] && [super isOpaque];
}

- (void)setTitle: (NSString*)aString
{
  [_titleCell setStringValue: aString];
  if (_formcell_auto_title_width)
    _titleWidth = [[_titleCell font] widthOfString: aString];
}

- (void)setTitleAlignment:(NSTextAlignment)mode
{
  [_titleCell setAlignment: mode];
}

- (void)setTitleFont: (NSFont*)fontObject
{
  [_titleCell setFont: fontObject];
}

- (void)setTitleWidth: (float)width
{
  if (_titleWidth >= 0)
    {
      _formcell_auto_title_width = NO;
      _titleWidth = width;
    }
  else 
    {
      _formcell_auto_title_width = YES;
      _titleWidth = [[_titleCell font] widthOfString: [_titleCell stringValue]];
    }
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

- (float)titleWidth
{
  return _titleWidth;
}

- (float)titleWidth: (NSSize)size
{
  // Minor TODO -- what is this supposed to do?
  return 0;
}

- (NSSize)cellSize
{
  NSSize returnedSize;
  NSSize titleSize = [_titleCell cellSize];
  NSSize textSize;
  
  textSize.width = [_cell_font widthOfString: @"minimum"];
  textSize.height = [_cell_font pointSize] + (2 * yDist) 
    + 2 * ((_sizeForBorderType (NSBezelBorder)).height); 
 
  returnedSize.width = titleSize.width + 4 + textSize.width;
  if (titleSize.height > textSize.height)
    returnedSize.height = titleSize.height;
  else
    returnedSize.height = textSize.height; 
  
  return returnedSize;
}

- (NSRect) drawingRectForBounds: (NSRect)theRect
{
  theRect.origin.x   += _titleWidth + 4;
  theRect.size.width -= _titleWidth + 4;
  
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

  //
  // Draw title
  //
  titleFrame.size.width = _titleWidth;
  [_titleCell drawWithFrame: titleFrame inView: controlView];

  //
  // Leave unfilled the space between titlecell and editable text.
  // 
  
  //
  // Draw border
  //
  borderedFrame.origin.x   += _titleWidth + 4;
  borderedFrame.size.width -= _titleWidth + 4;

  if (NSIsEmptyRect(borderedFrame))
    return;
  
  [controlView lockFocus];
  if (_cell.is_bordered)
    {
      [shadowCol set];
      NSFrameRect(borderedFrame);
    }
  else if (_cell.is_bezeled)
    {
      NSDrawWhiteBezel(borderedFrame, NSZeroRect);
    }
  [controlView unlockFocus];

  //
  // Draw interior
  //
  [self drawInteriorWithFrame: cellFrame inView: controlView];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // TODO
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  // TODO
  [super initWithCoder: aDecoder];

  return self;
}

@end

