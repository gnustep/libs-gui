/** <title>NSTextFieldCell</title>

   <abstract>Cell class for the text field entry control</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
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

#include "config.h"
#include <Foundation/NSNotification.h>
#include "AppKit/NSColor.h"
#include "AppKit/NSControl.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSTextFieldCell.h"
#include "AppKit/NSText.h"
#include "AppKit/NSEvent.h"

static NSColor	*bgCol;
static NSColor	*txtCol;

@interface NSTextFieldCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n;
// Minor optimization -- cache isOpaque.
- (BOOL) _isOpaque;
@end

@implementation	NSTextFieldCell (PrivateColor)
+ (void) _systemColorsChanged: (NSNotification*)n
{
  ASSIGN(bgCol, [NSColor textBackgroundColor]);
  ASSIGN(txtCol, [NSColor textColor]); 
}
- (BOOL) _isOpaque
{
  if (_textfieldcell_draws_background == NO 
      || _background_color == nil 
      || [_background_color alphaComponent] < 1.0)
    return NO;
  else
    return YES;   
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

  ASSIGN(_text_color, txtCol);
  ASSIGN(_background_color, bgCol);
  _textfieldcell_draws_background = NO;
  _textfieldcell_is_opaque = NO;
  _action_mask = NSKeyUpMask | NSKeyDownMask;
  return self;
}

- (void) dealloc
{
  RELEASE(_background_color);
  RELEASE(_text_color);
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSTextFieldCell *c = [super copyWithZone: zone];

  RETAIN (_background_color);
  RETAIN (_text_color);

  return c;
}

//
// Modifying Graphic Attributes 
//
- (void) setBackgroundColor: (NSColor *)aColor
{
  ASSIGN (_background_color, aColor);
  _textfieldcell_is_opaque = [self _isOpaque];
  if (_control_view)
    if ([_control_view isKindOfClass: [NSControl class]])
      [(NSControl *)_control_view updateCell: self];
}

- (NSColor *) backgroundColor
{
  return _background_color;
}

- (void) setDrawsBackground: (BOOL)flag
{
  _textfieldcell_draws_background = flag;
  _textfieldcell_is_opaque = [self _isOpaque];
  if (_control_view)
    if ([_control_view isKindOfClass: [NSControl class]])
      [(NSControl *)_control_view updateCell: self];
}

- (BOOL) drawsBackground
{
  return _textfieldcell_draws_background;
}

- (void) setTextColor: (NSColor *)aColor
{
  ASSIGN (_text_color, aColor);
  if (_control_view)
    if ([_control_view isKindOfClass: [NSControl class]])
      [(NSControl *)_control_view updateCell: self];
}

- (NSColor *) textColor
{
  return _text_color;
}

- (NSText *) setUpFieldEditorAttributes: (NSText *)textObject
{
  textObject = [super setUpFieldEditorAttributes: textObject];
  [textObject setDrawsBackground: _textfieldcell_draws_background];
  [textObject setBackgroundColor: _background_color];
  [textObject setTextColor: _text_color];
  return textObject;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (_textfieldcell_draws_background)
    {
      [_background_color set];
      NSRectFill ([self drawingRectForBounds: cellFrame]);
    }
  [super drawInteriorWithFrame: cellFrame inView: controlView];
}

- (BOOL) isOpaque
{
  return _textfieldcell_is_opaque;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL tmp;
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(id) at: &_background_color];
  [aCoder encodeValueOfObjCType: @encode(id) at: &_text_color];
  tmp = _textfieldcell_draws_background;
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &tmp];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      [self setBackgroundColor: [aDecoder decodeObjectForKey: @"NSBackgroundColor"]];
      [self setTextColor: [aDecoder decodeObjectForKey: @"NSTextColor"]];
      if ([aDecoder containsValueForKey: @"NSDrawsBackground"])
        {
	  [self setDrawsBackground: [aDecoder decodeBoolForKey: 
						  @"NSDrawsBackground"]];
	}
    }
  else
    {
      BOOL tmp;

      [aDecoder decodeValueOfObjCType: @encode(id) at: &_background_color];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_text_color];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tmp];
      _textfieldcell_draws_background = tmp;
      _textfieldcell_is_opaque = [self _isOpaque];
    }

  return self;
}

@end
