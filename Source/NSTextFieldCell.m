/* 
   NSTextFieldCell.m

   Cell class for the text field entry control

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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
#include <Foundation/NSString.h>
#include <Foundation/NSArray.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>

//
// TextFieldCell implementation
//
@implementation NSTextFieldCell

///////////////////////////////////////////////////////////////
//
// Class methods
//

+ (void) initialize
{
  if (self == [NSTextFieldCell class])
    {
      [self setVersion: 1];
    }
}

///////////////////////////////////////////////////////////////
//
// Instance methods
//
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

  [self setAlignment: NSLeftTextAlignment];
  [self setBackgroundColor: [NSColor textBackgroundColor]];
  [self setTextColor: [NSColor textColor]];
  [self setFont: [NSFont systemFontOfSize: 0]];
  draw_background = NO;
  return self;
}

- (void) dealloc
{
  [background_color release];
  [text_color release];
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSTextFieldCell	*c = [super copyWithZone: zone];

  [c setBackgroundColor: background_color];
  [c setTextColor: text_color];
  [c setDrawsBackground: draw_background];

  return c;
}

//
// Modifying Graphic Attributes 
//
- (NSColor *) backgroundColor
{
  return background_color;
}

- (BOOL) drawsBackground
{
  return draw_background;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
  [aColor retain];
  [background_color release];
  background_color = aColor;
}

- (void) setDrawsBackground: (BOOL)flag
{
  draw_background = flag;
}

- (void) setTextColor: (NSColor *)aColor
{
  [aColor retain];
  [text_color release];
  text_color = aColor;
}

- (id) setUpFieldEditorAttributes: (id)textObject
{
  return nil;
}

- (NSColor *) textColor
{
  return text_color;
}

- (void) setFont: (NSFont *)fontObject
{
  [super setFont: fontObject];
}

//
// Editing Text 
//
- (void) selectText: (id)sender
{
}

- (double) doubleValue
{
  return [super doubleValue];
}

- (void) setDoubleValue: (double)aDouble
{
  [super setDoubleValue: aDouble];
}

- (float) floatValue
{
  return [super floatValue];
}

- (void) setFloatValue: (float)aFloat
{
  [super setFloatValue: aFloat];
}

- (int) intValue
{
  return [super intValue];
}

- (void) setIntValue: (int)anInt
{
  [super setIntValue: anInt];
}

- (NSString *) stringValue
{
  return [super stringValue];
}

- (void) setStringValue: (NSString *)aString
{
  [super setStringValue: aString];
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (draw_background)
    {
      [controlView lockFocus];
      [background_color set];
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

  [aCoder encodeValueOfObjCType: @encode(id) at: &background_color];
  [aCoder encodeValueOfObjCType: @encode(id) at: &text_color];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &draw_background];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  [aDecoder decodeValueOfObjCType: @encode(id) at: &background_color];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &text_color];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &draw_background];

  return self;
}

@end
