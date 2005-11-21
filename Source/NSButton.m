/** <title>NSButton</title>

   <abstract>The button class</abstract>

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "config.h"

#include "AppKit/NSButton.h"
#include "AppKit/NSWindow.h"
#include "AppKit/NSButtonCell.h"
#include "AppKit/NSApplication.h"

//
// class variables
//
static id buttonCellClass = nil;

/**
 NSButton implementation
*/
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
/** Returns 
   
 */
+ (Class) cellClass
{
  return buttonCellClass;
}

+ (void) setCellClass: (Class)classId
{
  buttonCellClass = classId;
}

//
// Instance methods
//

- (BOOL) acceptsFirstMouse: (NSEvent *)theEvent
{
  return YES;
}

/** <p>Sets the NSButtonCell's type to <var>aType</var> and marks self for
    display.See <ref type="type" id="NSButtonType">NSButtonType</ref> for more
    informations.</p>
 */
- (void) setButtonType: (NSButtonType)aType
{
  [_cell setButtonType: aType];
  [self setNeedsDisplay: YES];
}

- (void)setHighlightsBy:(int)aType
{
  [_cell setHighlightsBy:aType];
}

- (void)setShowsStateBy:(int)aType
{
  [_cell setShowsStateBy:aType];
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

/**<p>Sets the NSButtonCell's state to <var>value</var> and marks
   self for display.</p><p>See Also: -state</p> 
 */
- (void) setState: (int)value
{
  [_cell setState: value];
  [self setNeedsDisplay: YES];
}

/** <p>Returns the NSButtonCell's state</p>
   <p>See Also: -setState:</p> */
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

/**<p>Sets the NSButtonCell to the next state and marks self for display.</p>
   <p>See Also: [NSButtonCell-setNextState]</p>
 */
- (void)setNextState
{
  [_cell setNextState];
  [self setNeedsDisplay: YES];
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

/**<p>Returns the NSButtonCell's alternate title</p>
   <p>See Also: -setAlternateTitle:</p>
 */
- (NSString *) alternateTitle
{
  return [_cell alternateTitle];
}

/**<p>Sets the NSButtonCell's alternateTitle to aString and marks self
   for display</p><p>See Also: -alternateTitle</p>
 */
- (void) setAlternateTitle: (NSString *)aString
{
  [_cell setAlternateTitle: aString];
  [self setNeedsDisplay: YES];
}

/**<p>Sets the NSButtonCell's title to aString and marks self for display
   </p><p>See Also: -title</p>
 */
- (void) setTitle: (NSString *)aString
{
  [_cell setTitle: aString];
  [self setNeedsDisplay: YES];
}

/** <p>Returns the NSButtonCell's title</p><p>See Also: -setTitle:</p>
 */
- (NSString *) title
{
  return [_cell title];
}

- (NSAttributedString *) attributedAlternateTitle
{
  return [_cell attributedAlternateTitle];
}

- (NSAttributedString *) attributedTitle
{
  return [_cell attributedTitle];
}

- (void) setAttributedAlternateTitle: (NSAttributedString *)aString
{
  [_cell setAttributedAlternateTitle: aString];
  [self setNeedsDisplay: YES];
}

- (void) setAttributedTitle: (NSAttributedString *)aString
{
  [_cell setAttributedTitle: aString];
  [self setNeedsDisplay: YES];
}

- (void) setTitleWithMnemonic: (NSString *)aString
{
  [_cell setTitleWithMnemonic: aString];
  [self setNeedsDisplay: YES];
}

//
// Setting the Images
//
/** <p>Returns the NSButtonCell's alternate image.</p>
    <p>See Also: -setAlternateImage:</p> 
*/
- (NSImage *) alternateImage
{
  return [_cell alternateImage];
}

/** <p>Returns the NSButtonCell's image</p>
    <p>See Also: -setImage:</p> 
*/
- (NSImage *) image
{
  return [_cell image];
}

/** <p>Returns the position of the NSButtonCell's image. See 
    <ref type="type" id="NSCellImagePosition">NSCellImagePosition</ref>
    for more informations. </p>
    <p>See Also: -setImagePosition:</p> 
*/
- (NSCellImagePosition) imagePosition
{
  return [_cell imagePosition];
}

/** <p>Sets the NSButtonCell's alternate image to anImage and marks self
    for display</p><p>See Also: -alternateImage </p>
*/
- (void) setAlternateImage: (NSImage *)anImage
{
  [_cell setAlternateImage: anImage];
  [self setNeedsDisplay: YES];
}

/** <p>Sets the NSButtonCell's image to anImage and marks self
    for display.</p><p>See Also: -image </p>
*/
- (void) setImage: (NSImage *)anImage
{
  [_cell setImage: anImage];
  [self setNeedsDisplay: YES];
}

/** <p>Sets the postion of the NSButtonCell's image to aPosition
    and marks self for display. See <ref type="type" id="NSCellImagePosition">
    NSCellImagePosition</ref>for more informations.</p>
    <p>See Also: -imagePosition </p>
*/
- (void) setImagePosition: (NSCellImagePosition)aPosition
{
  [_cell setImagePosition: aPosition];
  [self setNeedsDisplay: YES];
}

//
// Modifying Graphic Attributes
//
/** <p>Returns whether the NSButton's cell has border. 
    </p><p>See Also: -setBordered:</p>
*/
- (BOOL) isBordered
{
  return [_cell isBordered];
}

/** <p>Returns whether the NSButton's cell is transparent</p>
    <p>See Also: -setTransparent:</p>
*/
- (BOOL) isTransparent
{
  return [_cell isTransparent];
}

/** <p>Sets whether the NSButton's cell has border and marks self for 
    display.</p>
    <p>See Also: -isBordered</p>
*/
- (void) setBordered: (BOOL)flag
{
  [_cell setBordered: flag];
  [self setNeedsDisplay: YES];
}

/** <p>Sets whether the NSButton's cell is transparent and marks self for 
    display</p><p>See Also: -isTransparent</p>
*/
- (void) setTransparent: (BOOL)flag
{
  [_cell setTransparent: flag];
  [self setNeedsDisplay: YES];
}

/** <p>Returns the style of the NSButtonCell's bezeled border. 
    See <ref type="type" id="NSBezelStyle">NSBezelStyle</ref> for more
    informations</p><p>See Also: -setBezelStyle:</p>
*/
- (NSBezelStyle)bezelStyle
{
  return [_cell bezelStyle];
}

/**<p>Sets the style of the NSButtonCell's bezeled border and marks self for
   display. See <ref type="type" id="NSBezelStyle">NSBezelStyle</ref>
   for more informations</p> <p>See Also: -bezelStyle</p>
*/
- (void)setBezelStyle:(NSBezelStyle)bezelStyle
{
  [_cell setBezelStyle: bezelStyle];
  [self setNeedsDisplay: YES];
}

- (BOOL)showsBorderOnlyWhileMouseInside
{
  return [_cell showsBorderOnlyWhileMouseInside];
}

- (void)setShowsBorderOnlyWhileMouseInside:(BOOL)show
{
  [_cell setShowsBorderOnlyWhileMouseInside: show];
  [self setNeedsDisplay: YES];
}

//
// Displaying
//
/** TODO
 */
- (void) highlight: (BOOL)flag
{
  [_cell highlight: flag withFrame: _bounds inView: self];
}

//
// Setting the Key Equivalent
//
/**<p>Returns the NSButtonCell's key equivalent. This is used in
   -performKeyEquivalent: ... TODO</p><p>See Also: -setKeyEquivalent:</p>
 */
- (NSString*) keyEquivalent
{
  return [_cell keyEquivalent];
}

/** <p>Returns the modifier mask of the NSButtonCell's key equivalent. 
   This is used in   -performKeyEquivalent: ... TODO</p>
   <p>See Also: -setKeyEquivalentModifierMask:</p>
 */
- (unsigned int) keyEquivalentModifierMask
{
  return [_cell keyEquivalentModifierMask];
}

/** <p>Sets the NSButtonCell's key equivalent.This is used in
    -performKeyEquivalent: </p> <p>See Also: -keyEquivalent</p>
*/
- (void) setKeyEquivalent: (NSString*)aKeyEquivalent
{
  [_cell setKeyEquivalent: aKeyEquivalent];
}

/** <p>Sets the modifier mask of the NSButtonCell's key equivalent.
    This is used in -performKeyEquivalent:</p>
   <p>See Also: -keyEquivalentModifierMask</p>
*/
- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  [_cell setKeyEquivalentModifierMask: mask];
}

//
// Determining the first responder
//
- (BOOL) becomeFirstResponder
{
  [_window disableKeyEquivalentForDefaultButtonCell];
  [_cell setShowsFirstResponder: YES];
  [self setNeedsDisplay: YES];

  return YES;
}

- (BOOL) resignFirstResponder
{
  [_window enableKeyEquivalentForDefaultButtonCell];
  [_cell setShowsFirstResponder: NO];
  [self setNeedsDisplay: YES];

  return YES;
}

- (void) becomeKeyWindow
{
  [_cell setShowsFirstResponder: YES];
  [self setNeedsDisplay: YES];
}

- (void) resignKeyWindow
{
  [_cell setShowsFirstResponder: NO];
  [self setNeedsDisplay: YES];
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
/** TODO 
 */
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

- (void) setSound: (NSSound *)aSound
{
  [_cell setSound: aSound];
}

- (NSSound *) sound
{
  return [_cell sound];
}

@end
