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
  [self initTextCell:@""];
  return self;
}

- initTextCell:(NSString *)aString
{
  [super initTextCell:aString];

  [self setEnabled:YES];
  [self setBordered:YES];
  [self setBezeled:YES];
  [self setScrollable:YES];
  [self setEditable:YES];
  [self setAlignment:NSLeftTextAlignment];

  [self setBackgroundColor: [NSColor whiteColor]];
  [self setTextColor: [NSColor blackColor]];
  [self setFont: [NSFont systemFontOfSize:0]];
  draw_background = YES;
  return self;
}

- (void)dealloc
{
  [background_color release];
  [text_color release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
  NSTextFieldCell* c = [super copyWithZone:zone];

  [c setBackgroundColor: background_color];
  [c setTextColor: text_color];
  [c setDrawsBackground: draw_background];

  return c;
}

//
// Determining Component Sizes 
//
- (NSSize)cellSize
{
  NSFont *f;
  NSSize borderSize, s;

  // Get border size
  if ([self isBordered])
    {
      if ([self isBezeled])
	borderSize = [NSCell sizeForBorderType: NSBezelBorder];
      else
	borderSize = [NSCell sizeForBorderType: NSLineBorder];
    }
  else
    borderSize = [NSCell sizeForBorderType: NSNoBorder];

  // Get size of text with a little buffer space
  f = [self font];
  s = NSMakeSize([f widthOfString: [self stringValue]] + 2,
		 [f pointSize] + 2);

  // Add in border size
  s.width += 2 * borderSize.width;
  s.height += 2 * borderSize.height;

  return s;
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
  [aColor retain];
  [background_color release];
  background_color = aColor;
}

- (void)setDrawsBackground:(BOOL)flag
{
  draw_background = flag;
}

- (void)setTextColor:(NSColor *)aColor
{
  [aColor retain];
  [text_color release];
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
  [super drawWithFrame:cellFrame inView:controlView];
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
