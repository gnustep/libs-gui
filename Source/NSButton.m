/*
   NSButton.m

   The button class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
	    Ovidiu Predescu <ovidiu@net-community.com>
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

#include <AppKit/NSButton.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSApplication.h>

//
// class variables
//
id _nsbuttonCellClass = nil;

//
// NSButton implementation
//
@implementation NSButton

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSButton class])
    {
      [self setVersion: 1];
      [self setCellClass: [NSButtonCell class]];
    }
}

//
// Initializing the NSButton Factory
//
+ (Class) cellClass
{
  return _nsbuttonCellClass;
}

+ (void) setCellClass: (Class)classId
{
  _nsbuttonCellClass = classId;
}

//
// Instance methods
//
//
// Initialization
//
- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (id) initWithFrame: (NSRect)frameRect
{
  NSCell	*aCell;

  [super initWithFrame: frameRect];

  // set our cell
  aCell = [[[self class] cellClass] new];
  [self setCell: aCell];
  RELEASE(aCell);

  return self;
}

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

//
// Setting the Button Type
//
- (void) setButtonType: (NSButtonType)aType
{
  [_cell setButtonType: aType];
  [self display];
}

//
// Setting the State
//
- (void) setIntValue: (int)anInt
{
  [self setState: (anInt != 0)];
}

- (void) setFloatValue: (float)aFloat
{
  [self setState: (aFloat != 0)];
}

- (void) setDoubleValue: (double)aDouble
{
  [self setState: (aDouble != 0)];
}

- (void) setState: (int)value
{
  [_cell setState: value];
  [self display];
}

- (int) state
{
  return [_cell state];
}

- (BOOL) allowsMixedState
{
  return [_cell allowsMixedState];
}

- (void) setAllowsMixedState: (BOOL)flag
{
  [_cell setAllowsMixedState: flag];
}

- (void)setNextState
{
  [_cell setNextState];
}

//
// Setting the Repeat Interval
//
- (void) getPeriodicDelay: (float *)delay
		interval: (float *)interval
{
  [_cell getPeriodicDelay: delay interval: interval];
}

- (void) setPeriodicDelay: (float)delay
		interval: (float)interval
{
  [_cell setPeriodicDelay: delay interval: interval];
}

//
// Setting the Titles
//
- (NSString *) alternateTitle
{
  return [_cell alternateTitle];
}

- (void) setAlternateTitle: (NSString *)aString
{
  [_cell setAlternateTitle: aString];
  [self display];
}

- (void) setTitle: (NSString *)aString
{
  [_cell setTitle: aString];
  [self display];
}

- (NSString *) title
{
  return [_cell title];
}

//
// Setting the Images
//
- (NSImage *) alternateImage
{
  return [_cell alternateImage];
}

- (NSImage *) image
{
  return [_cell image];
}

- (NSCellImagePosition) imagePosition
{
  return [_cell imagePosition];
}

- (void) setAlternateImage: (NSImage *)anImage
{
  [_cell setAlternateImage: anImage];
  [self display];
}

- (void) setImage: (NSImage *)anImage
{
  [_cell setImage: anImage];
  [self display];
}

- (void) setImagePosition: (NSCellImagePosition)aPosition
{
  [_cell setImagePosition: aPosition];
  [self display];
}

- (void) setAlignment: (NSTextAlignment)mode
{
  [_cell setAlignment: mode];
}

- (NSTextAlignment) alignment
{
  return [_cell alignment];
}

//
// Modifying Graphic Attributes
//
- (BOOL) isBordered
{
  return [_cell isBordered];
}

- (BOOL) isTransparent
{
  return [_cell isTransparent];
}

- (void) setBordered: (BOOL)flag
{
  [_cell setBordered: flag];
  [self display];
}

- (void) setTransparent: (BOOL)flag
{
  [_cell setTransparent: flag];
  [self display];
}

//
// Displaying
//

- (void) highlight: (BOOL)flag
{
  [_cell highlight: flag withFrame: _bounds inView: self];
}

//
// Setting the Key Equivalent
//
- (NSString*) keyEquivalent
{
  return [_cell keyEquivalent];
}

- (unsigned int) keyEquivalentModifierMask
{
  return [_cell keyEquivalentModifierMask];
}

- (void) setKeyEquivalent: (NSString*)aKeyEquivalent
{
  [_cell setKeyEquivalent: aKeyEquivalent];
}

- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  [_cell setKeyEquivalentModifierMask: mask];
}

//
// Determining the first responder
//
- (BOOL) acceptsFirstResponder
{
  return [self isEnabled];
}

- (void) keyDown: (NSEvent*)theEvent
{
  if ([self isEnabled])
    {
      NSString *characters = [theEvent characters];
      unichar character = 0;

      if ([characters length] > 0)
	{
	  character = [characters characterAtIndex: 0];
	}

      // Handle SPACE or RETURN to perform a click
      if ((character ==  NSNewlineCharacter)
	  || (character == NSEnterCharacter) 
	  || (character == NSCarriageReturnCharacter)
	  || ([characters isEqualToString: @" "]))
	{
	  [self performClick: self];
	  return;
	}      
    }
  
  [super keyDown: theEvent];
}

//
// Handling Events and Action Messages
//

- (void) performClick: (id)sender
{
  [_cell performClick: sender];
}

- (BOOL) performKeyEquivalent: (NSEvent *)anEvent
{
  if ([self isEnabled])
    {
      NSString	*key = [self keyEquivalent];

      if (key != nil && [key isEqual: [anEvent charactersIgnoringModifiers]])
	{
	  unsigned int	mask = [self keyEquivalentModifierMask];

	  if (([anEvent modifierFlags] & mask) == mask)
	    {
	      [self performClick: self];
	      return YES;
	    }
	}
    }
  return NO;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  return self;
}

@end
