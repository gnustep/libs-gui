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
- init
{
  return [self initWithFrame: NSZeroRect];
}

- initWithFrame: (NSRect)frameRect
{
  [super initWithFrame: frameRect];

  // set our cell
  [self setCell: [[_nsbuttonCellClass new] autorelease]];

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
  [cell setButtonType: aType];
  [self display];
}

//
// Identifying the Selected Cell
//
- (id) selectedCell
{
  return cell;
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
  [cell setState: value];
  [self display];
}

- (int) state
{
  return [cell state];
}

//
// Setting the Repeat Interval
//
- (void) getPeriodicDelay: (float *)delay
		interval: (float *)interval
{
  [cell getPeriodicDelay: delay interval: interval];
}

- (void) setPeriodicDelay: (float)delay
		interval: (float)interval
{
  [cell setPeriodicDelay: delay interval: interval];
}

//
// Setting the Titles
//
- (NSString *) alternateTitle
{
  return [cell alternateTitle];
}

- (void) setAlternateTitle: (NSString *)aString
{
  [cell setAlternateTitle: aString];
  [self display];
}

- (void) setTitle: (NSString *)aString
{
  [cell setTitle: aString];
  [self display];
}

- (NSString *) title
{
  return [cell title];
}

//
// Setting the Images
//
- (NSImage *) alternateImage
{
  return [cell alternateImage];
}

- (NSImage *) image
{
  return [cell image];
}

- (NSCellImagePosition) imagePosition
{
  return [cell imagePosition];
}

- (void) setAlternateImage: (NSImage *)anImage
{
  [cell setAlternateImage: anImage];
  [self display];
}

- (void) setImage: (NSImage *)anImage
{
  [cell setImage: anImage];
  [self display];
}

- (void) setImagePosition: (NSCellImagePosition)aPosition
{
  [cell setImagePosition: aPosition];
  [self display];
}

- (void) setAlignment: (NSTextAlignment)mode
{
  [cell setAlignment: mode];
}

- (NSTextAlignment) alignment
{
  return [cell alignment];
}

//
// Modifying Graphic Attributes
//
- (BOOL) isBordered
{
  return [cell isBordered];
}

- (BOOL) isTransparent
{
  return [cell isTransparent];
}

- (void) setBordered: (BOOL)flag
{
  [cell setBordered: flag];
  [self display];
}

- (void) setTransparent: (BOOL)flag
{
  [cell setTransparent: flag];
  [self display];
}

//
// Displaying
//
- (void) drawRect: (NSRect)rect
{
  [cell drawWithFrame: rect inView: self];
}

- (void) highlight: (BOOL)flag
{
  [cell highlight: flag withFrame: bounds inView: self];
}

//
// Setting the Key Equivalent
//
- (NSString*) keyEquivalent
{
  return [cell keyEquivalent];
}

- (unsigned int) keyEquivalentModifierMask
{
  return [cell keyEquivalentModifierMask];
}

- (void) setKeyEquivalent: (NSString*)aKeyEquivalent
{
  [cell setKeyEquivalent: aKeyEquivalent];
}

- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  [cell setKeyEquivalentModifierMask: mask];
}

//
// Determining the first responder
//
- (BOOL) acceptsFirstResponder
{
  return [cell acceptsFirstResponder] || ([self keyEquivalent] != nil);
}

- (void) keyDown: (NSEvent*)theEvent
{
  if ([self performKeyEquivalent: theEvent] == NO)
    [super keyDown: theEvent];
}

//
// Handling Events and Action Messages
//

- (void) performClick: (id)sender
{
  [self lockFocus];
  [cell performClick: sender];
  [self unlockFocus];
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
