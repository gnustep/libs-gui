/* 
   NSTextFieldCell.m

   Cell class for the text field entry control

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
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
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSText.h>

static NSColor	*bgCol;
static NSColor	*txtCol;

@interface NSTextFieldCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n;
@end

@implementation	NSTextFieldCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n
{
  ASSIGN(bgCol, [NSColor textBackgroundColor]);
  ASSIGN(txtCol, [NSColor textColor]); 
}
@end

@implementation NSTextFieldCell
+ (void) initialize
{
  if (self == [NSTextFieldCell class])
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

//
// Initialization
//
- (id) init
{
  [self initTextCell: @""];
  return self;
}

- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];
  text_align = NSLeftTextAlignment;

  ASSIGN(_text_color, txtCol);
  ASSIGN(_background_color, bgCol);
  _draws_background = NO;
  return self;
}

- (void) dealloc
{
  [_background_color release];
  [_text_color release];
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSTextFieldCell *c = [super copyWithZone: zone];

  [c setBackgroundColor: _background_color];
  [c setTextColor: _text_color];
  [c setDrawsBackground: _draws_background];

  return c;
}

//
// Modifying Graphic Attributes 
//
- (void) setBackgroundColor: (NSColor *)aColor
{
  ASSIGN (_background_color, aColor); 
}

- (NSColor *) backgroundColor
{
  return _background_color;
}

- (void) setDrawsBackground: (BOOL)flag
{
  _draws_background = flag;
}

- (BOOL) drawsBackground
{
  return _draws_background;
}

- (void) setTextColor: (NSColor *)aColor
{
  ASSIGN (_text_color, aColor);
}

- (NSColor *) textColor
{
  return _text_color;
}

- (NSText *) setUpFieldEditorAttributes: (NSText *)textObject
{
  textObject = [super setUpFieldEditorAttributes: textObject];
  [textObject setDrawsBackground: _draws_background];
  [textObject setBackgroundColor: _background_color];
  [textObject setTextColor: _text_color];
  return textObject;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (_draws_background)
    {
      [controlView lockFocus];
      [_background_color set];
      NSRectFill ([self drawingRectForBounds: cellFrame]);
      [controlView unlockFocus];
    }
  [super drawInteriorWithFrame: cellFrame inView: controlView];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(id) at: &_background_color];
  [aCoder encodeValueOfObjCType: @encode(id) at: &_text_color];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_draws_background];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &_background_color];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_text_color];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_draws_background];

  return self;
}

@end
