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

#include <gnustep/gui/NSTextFieldCell.h>
#include <gnustep/gui/NSTextField.h>
#include <gnustep/gui/NSWindow.h>
#include <Foundation/NSArray.h>
#include <gnustep/gui/NSApplication.h>

//
// TextFieldCell implementation
//
@implementation NSTextFieldCell

///////////////////////////////////////////////////////////////
//
// Class methods
//

+ (void)initialize
{
  if (self == [NSTextFieldCell class])
    {
      // Initial version
      [self setVersion:1];
    }
}

///////////////////////////////////////////////////////////////
//
// Instance methods
//
//
// Initialization
//
- init
{
  [self initTextCell:[NSString stringWithCString:"Field"]];
  return self;
}

- initTextCell:(NSString *)aString
{
  [super initTextCell:aString];

  [self setEnabled:YES];
  [self setBordered:YES];
  [self setScrollable:YES];
  [self setEditable:YES];
  [self setAlignment:NSLeftTextAlignment];
	
  background_color = [NSColor whiteColor];
  text_color = [NSColor blackColor];
  return self;
}

//
// Modifying Graphic Attributes 
//
- (NSColor *)backgroundColor
{
  return background_color;
}

- (BOOL)drawsBackground
{
  return draw_background;
}

- (void)setBackgroundColor:(NSColor *)aColor
{
  background_color = aColor;
}

- (void)setDrawsBackground:(BOOL)flag
{
  draw_background = flag;
}

- (void)setTextColor:(NSColor *)aColor
{
  text_color = aColor;
}

- (id)setUpFieldEditorAttributes:(id)textObject
{
  return nil;
}

- (NSColor *)textColor
{
  return text_color;
}

- (void)setFont:(NSFont *)fontObject
{
  [super setFont:fontObject];
}

//
// Editing Text 
//
- (void)selectText:(id)sender
{
}

- (double)doubleValue
{
  return [super doubleValue];
}

- (void)setDoubleValue:(double)aDouble
{
  [super setDoubleValue:aDouble];
}

- (float)floatValue
{
  return [super floatValue];
}

- (void)setFloatValue:(float)aFloat
{
  [super setFloatValue:aFloat];
}

- (int)intValue
{
  return [super intValue];
}

- (void)setIntValue:(int)anInt
{
  [super setIntValue:anInt];
}

- (NSString *)stringValue
{
  return [super stringValue];
}

- (void)setStringValue:(NSString *)aString
{
  [super setStringValue:aString];
}

//
// Displaying
//
- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView
{
  // Save last view drawn to
  control_view = controlView;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: background_color];
  [aCoder encodeObject: text_color];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &draw_background];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  background_color = [aDecoder decodeObject];
  text_color = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &draw_background];

  return self;
}

@end
