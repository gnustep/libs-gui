/* 
   NSBrowserCell.m

   Cell class for the NSBrowser

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

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
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSImage.h>

// Class variables
static NSImage *branch_image;
static NSImage *highlight_image;

// Private methods
@interface NSBrowserCell (Private)
- (void)setBranchImageCell:aCell;
- (void)setHighlightBranchImageCell:aCell;
- (void)setTextFieldCell:aCell;
@end

@implementation NSBrowserCell (Private)

- (void)setBranchImageCell:aCell
{
  _branchImage = aCell;
}

- (void)setHighlightBranchImageCell:aCell
{
  _highlightBranchImage = aCell;
}

- (void)setTextFieldCell:aCell
{
  _browserText = aCell;
}

@end

//
// NSBrowserCell implementation
//
@implementation NSBrowserCell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSBrowserCell class])
    {
      // Initial version
      [self setVersion:1];

      // The default images
      branch_image = [NSImage imageNamed: @"common_ArrowRight"];
      highlight_image = [NSImage imageNamed: @"common_ArrowRightH"];
    }
}

//
// Accessing Graphic Attributes 
//
+ (NSImage *)branchImage
{
  return branch_image;
}

+ (NSImage *)highlightedBranchImage
{
  return highlight_image;
}

//
// Instance methods
//

- init
{
  return [self initTextCell: @"aTitle"];
}

- initTextCell:(NSString *)aString
{
  [super initTextCell: aString];

  // Our image cells
  _branchImage = [[NSCell alloc] initImageCell: [NSBrowserCell branchImage]];
  _highlightBranchImage = [[NSCell alloc] initImageCell:
			        [NSBrowserCell highlightedBranchImage]];

  // Our text cell
  _browserText = [[NSTextFieldCell alloc] initTextCell: aString];
  [_browserText setEditable: NO];
  [_browserText setBordered: NO];
  [_browserText setDrawsBackground: YES];

  _alternateImage = nil;
  _isLeaf = NO;
  _isLoaded = NO;

  return self;
}

- (void)dealloc
{
  [_branchImage release];
  [_highlightBranchImage release];
  [_alternateImage release];
  [_browserText release];

  [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
  NSBrowserCell* c = [super copyWithZone:zone];

  // Copy the image cells
  [c setBranchImageCell: [_branchImage copy]];
  [c setHighlightBranchImageCell: [_branchImage copy]];
  [c setAlternateImage: _alternateImage];

  // Copy the text cell
  [c setTextFieldCell: [_browserText copy]];

  [c setLeaf: _isLeaf];
  [c setLoaded: NO];

  return c;
}

//
// Accessing Graphic Attributes 
//
- (NSImage *)alternateImage
{
  return _alternateImage;
}

- (void)setAlternateImage:(NSImage *)anImage
{
  [anImage retain];
  [_alternateImage release];
  _alternateImage = anImage;

  // Set the image in our highlight cell
  if (_alternateImage)
    [_highlightBranchImage setImage: _alternateImage];
  else
    [_highlightBranchImage setImage: [NSBrowserCell highlightedBranchImage]];
}

//
// Placing in the Browser Hierarchy 
//
- (BOOL)isLeaf
{
  return _isLeaf;
}

- (void)setLeaf:(BOOL)flag
{
  _isLeaf = flag;
}

//
// Determining Loaded Status 
//
- (BOOL)isLoaded
{
  return _isLoaded;
}

- (void)setLoaded:(BOOL)flag
{
  _isLoaded = flag;
}

//
// Setting State 
//
- (void)reset
{
  cell_highlighted = NO;
  cell_state = NO;
}

- (void)set
{
  cell_highlighted = YES;
  cell_state = YES;
}

//
// Setting the NSCell's Value 
//
- (double)doubleValue
{
  return [_browserText doubleValue];
}

- (float)floatValue;
{
  return [_browserText floatValue];
}

- (int)intValue
{
  return [_browserText intValue];
}

- (NSString *)stringValue
{
  return [_browserText stringValue];
}

- (void)setDoubleValue:(double)aDouble
{
  [_browserText setDoubleValue: aDouble];
}

- (void)setFloatValue:(float)aFloat
{
  [_browserText setFloatValue: aFloat];
}

- (void)setIntValue:(int)anInt
{
  [_browserText setIntValue: anInt];
}

- (void)setStringValue:(NSString *)aString
{
  [_browserText setStringValue: aString];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObject: _browserText];
  [aCoder encodeObject: _branchImage];
  [aCoder encodeObject: _highlightBranchImage];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isLeaf];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  _browserText = [aDecoder decodeObject];
  _branchImage = [aDecoder decodeObject];
  _highlightBranchImage = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isLeaf];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];

  return self;
}

@end
