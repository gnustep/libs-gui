/* 
   NSButtonCell.m

   The button cell class

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

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#include <gnustep/gui/NSButtonCell.h>
#include <gnustep/gui/NSButton.h>
#include <gnustep/gui/NSWindow.h>
#include <Foundation/NSLock.h>
#include <Foundation/NSArray.h>
#include <gnustep/gui/NSEvent.h>
#include <gnustep/gui/NSApplication.h>

//
// NSButtonCell implementation
//
@implementation NSButtonCell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSButtonCell class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Instance methods
//
- init
{
  [self initTextCell:[NSString stringWithCString:"Button"]];
  return self;
}

- initImageCell:(NSImage *)anImage
{
  [super initImageCell:anImage];
  cell_type = NSMomentaryPushButton;
  [self setEnabled:YES];
  transparent = NO;
  [self setBordered:YES];
  return self;
}

- initTextCell:(NSString *)aString
{
  [super initTextCell:aString];
  support = [NSFont userFixedPitchFontOfSize:12];
  alt_contents = @"Button";
  cell_type = NSMomentaryPushButton;
  [self setEnabled:YES];
  transparent = NO;
  [self setBordered:YES];
  return self;
}

- (void)dealloc
{
  [super dealloc];
}

//
// Setting the Titles 
//
- (NSString *)alternateTitle
{
  return alt_contents;
}

- (void)setAlternateTitle:(NSString *)aString
{
  alt_contents = aString;
  // update our state
  [self setState:[self state]];
}

- (void)setFont:(NSFont *)fontObject
{
  [super setFont:fontObject];
}

- (void)setTitle:(NSString *)aString
{
  [self setStringValue:aString];
  // update our state
  [self setState:[self state]];
}

- (NSString *)title
{
  return [self stringValue];
}

//
// Setting the Images 
//
- (NSImage *)alternateImage
{
  return alt_image;
}

- (NSCellImagePosition)imagePosition
{
  return image_position;
}

- (void)setAlternateImage:(NSImage *)anImage
{
  alt_image = anImage;
}

- (void)setImagePosition:(NSCellImagePosition)aPosition
{
  image_position = aPosition;
}

//
// Setting the Repeat Interval 
//
- (void)getPeriodicDelay:(float *)delay
		interval:(float *)interval
{}

- (void)setPeriodicDelay:(float)delay
		interval:(float)interval
{}

//
// Setting the Key Equivalent 
//
- (NSString *)keyEquivalent
{
  return nil;
}

- (NSFont *)keyEquivalentFont
{
  return nil;
}

- (unsigned int)keyEquivalentModifierMask
{
  return 0;
}

- (void)setKeyEquivalent:(NSString *)aKeyEquivalent
{}

- (void)setKeyEquivalentModifierMask:(unsigned int)mask
{}

- (void)setKeyEquivalentFont:(NSFont *)fontObj
{}

- (void)setKeyEquivalentFont:(NSString *)fontName 
			size:(float)fontSize
{}

//
// Modifying Graphic Attributes 
//
- (BOOL)isOpaque
{
  return NO;
}

- (BOOL)isTransparent
{
  return transparent;
}

- (void)setTransparent:(BOOL)flag
{
  transparent = flag;
}

//
// Modifying Graphic Attributes 
//
- (int)highlightsBy
{
  return 0;
}

- (void)setHighlightsBy:(int)aType
{}

- (void)setShowsStateBy:(int)aType
{}

- (void)setType:(NSButtonType)aType
{
  cell_type = aType;

  // update our state
  [self setState:[self state]];
}

- (int)showsStateBy
{
  return 0;
}

- (void)setState:(int)value
{
  [super setState:value];
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
// Simulating a Click 
//
- (void)performClick:(id)sender
{
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  NSLog(@"NSButtonCell: start encoding\n");
  [aCoder encodeObject: alt_contents];
  [aCoder encodeObject: alt_image];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &transparent];
  NSLog(@"NSButtonCell: finish encoding\n");
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  NSLog(@"NSButtonCell: start decoding\n");
  alt_contents = [aDecoder decodeObject];
  alt_image = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &transparent];
  NSLog(@"NSButtonCell: finish decoding\n");
  return self;
}

@end
