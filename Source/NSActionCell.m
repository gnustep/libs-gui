/** <title>NSActionCell</title>

   <abstract>Abstract cell for target/action paradigm</abstract>

   Copyright (C) 1996-1999 Free Software Foundation, Inc.

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

#include "config.h"
#include <Foundation/NSCoder.h>
#include "AppKit/NSActionCell.h"
#include "AppKit/NSControl.h"

@implementation NSActionCell

static Class controlClass;

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSActionCell class])
    {
      controlClass = [NSControl class];
      [self setVersion: 1];
    }
}

/*
 * Instance methods
 */

/*
 * Configuring an NSActionCell 
 */

/**
 * Sets the alignment of text within the receiver.
 */
- (void) setAlignment: (NSTextAlignment)mode
{
  [super setAlignment: mode];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/**
 * If <code>YES</code> then the receiver is drawn with a bezeled border.
 */
- (void) setBezeled: (BOOL)flag
{
  _cell.is_bezeled = flag;
  if (_cell.is_bezeled)
    _cell.is_bordered = NO;
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/**
 * If <code>YES</code> then receiver is drawn with a border.
 */
- (void) setBordered: (BOOL)flag
{
  _cell.is_bordered = flag;
  if (_cell.is_bordered)
    _cell.is_bezeled = NO;
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/**
 * If <code>YES</code> then the receiver is capable of accepting input.
 */
- (void) setEnabled: (BOOL)flag
{
  _cell.is_disabled = !flag;
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

- (void) setFloatingPointFormat: (BOOL)autoRange
			   left: (unsigned int)leftDigits
			  right: (unsigned int)rightDigits
{
  [super setFloatingPointFormat: autoRange
	 left: leftDigits
	 right: rightDigits];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/**
 * Sets the font to be used in the receiver.
 */
- (void) setFont: (NSFont*)fontObject
{
  [super setFont: fontObject];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
  // TODO: This should also set the font of the text object, when selected
}

/**
 * Sets the image to be displayed in the receiver.
 */
- (void) setImage: (NSImage*)image
{
  [super setImage: image];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/*
 * Manipulating NSActionCell Values 
 */

/**
 * Retrieve the value of the receiver as an NSString.
 */
- (NSString *)stringValue
{
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view validateEditing];
  return [super stringValue];
}

/**
 * Retrieve the value of the receiver as a double.
 */
- (double)doubleValue
{
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view validateEditing];
  return [super doubleValue];
}

/**
 * Retrieve the value of the receiver as a float.
 */
- (float)floatValue
{
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view validateEditing];
  return [super floatValue];
}

/**
 * Retrieve the value of the receiver as an int.
 */
- (int)intValue
{
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view validateEditing];
  return [super intValue];
}

/**
 * Set the value of the receiver from anObject.
 */
- (void) setObjectValue: (id)anObject
{
  [super setObjectValue: anObject];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/**
 * Set the value of the receiver from aString.
 */
- (void) setStringValue: (NSString*)aString
{
  [super setStringValue: aString];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/**
 * Set the value of the receiver from aDouble.
 */
- (void) setDoubleValue: (double)aDouble
{
  [super setDoubleValue: aDouble];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/**
 * Set the value of the receiver from aFloat.
 */
- (void) setFloatValue: (float)aFloat
{
  [super setFloatValue: aFloat];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/**
 * Set the value of the receiver from anInt.
 */
- (void) setIntValue: (int)anInt
{
  [super setIntValue: anInt];
  if (_control_view)
    if ([_control_view isKindOfClass: controlClass])
      [(NSControl *)_control_view updateCell: self];
}

/*
 * Target and Action 
 */

/**
 * Retrieve the action from the receiver.
 */
- (SEL) action
{
  return _action;
}

/**
 * Set the action in the receiver as the selector aSelector.
 */
- (void) setAction: (SEL)aSelector
{
  _action = aSelector;
}

/**
 * Set the target in the receiver as anObject.  NSActionCell does not retain its target! 
 */
- (void) setTarget: (id)anObject
{
  _target = anObject;
}

/**
 * Return the target of the receiver.
 */
- (id) target
{
  return _target;
}

/**
 * Assigning a Tag. 
 */
- (void) setTag: (int)anInt
{
  _tag = anInt;
}

/**
 * Return the tag.
 */
- (int) tag
{
  return _tag;
}

/**
 * Returns the control view of the receiver.
 */
-(NSView *)controlView
{
  return _control_view;
}


- (void) drawWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
  if (_control_view != controlView)
    _control_view = controlView;

  [super drawWithFrame: cellFrame 
	 inView: controlView];
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_tag];
  [aCoder encodeConditionalObject: _target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_action];
  [aCoder encodeConditionalObject: _control_view];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_tag];
  _target = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];
  _control_view = [aDecoder decodeObject];
  return self;
}

@end
