/* 
   NSTextField.m

   Text field control class for text entry

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

#include <gnustep/gui/NSTextField.h>
#include <gnustep/gui/NSWindow.h>
#include <gnustep/gui/NSTextFieldCell.h>
#include <gnustep/gui/NSApplication.h>

//
// class variables
//
id MB_NSTEXTFIELDCELL_CLASS;

@implementation NSTextField

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSTextField class])
    {
      // Initial version
      [self setVersion:1];

      // Set our cell class to NSTextFieldCell
      [self setCellClass:[NSTextFieldCell class]];
    }
}

//
// Initializing the NSTextField Factory 
//
+ (Class)cellClass
{
  return MB_NSTEXTFIELDCELL_CLASS;
}

+ (void)setCellClass:(Class)classId
{
  MB_NSTEXTFIELDCELL_CLASS = classId;
}

//
// Instance methods
//
- init
{
  return [self initWithFrame:NSZeroRect];
}

- initWithFrame:(NSRect)frameRect
{
  [super initWithFrame:frameRect];

  // set our cell
  [[self cell] release];
  [self setCell:[[MB_NSTEXTFIELDCELL_CLASS alloc] init]];
  [cell setState:1];
  text_cursor = [NSCursor IBeamCursor];

  return self;
}

//
// Setting User Access to Text 
//
- (BOOL)isEditable
{
  return [cell isEditable];
}

- (BOOL)isSelectable
{
  return [cell isSelectable];
}

- (void)setEditable:(BOOL)flag
{
  [cell setEditable:flag];
}

- (void)setSelectable:(BOOL)flag
{
  [cell setSelectable:flag];
}

//
// Editing Text 
//
- (void)selectText:(id)sender
{
  if ([[self window] makeFirstResponder:self])
    [cell selectText:sender];
}

//
// Setting Tab Key Behavior 
//
- (id)nextText
{
  return next_text;
}

- (id)previousText
{
  return previous_text;
}

- (void)setNextText:(id)anObject
{
  id t;

  next_text = anObject;

  // Tell the object that we are the previous text
  // Unless it already knows that
  if ([anObject respondsToSelector:@selector(setPreviousText:)])
    {
      t = [anObject previousText];
      if (t != self)
	[anObject setPreviousText:self];
    }
}

- (void)setPreviousText:(id)anObject
{
  id t;

  previous_text = anObject;

  // Tell the object that we are the next text
  // Unless it already knows that
  if ([anObject respondsToSelector:@selector(setNextText:)])
    {
      t = [anObject nextText];
      if (t != self)
	[anObject setNextText:self];
    }
}

//
// Assigning a Delegate 
//
- (void)setDelegate:(id)anObject
{
  text_delegate = anObject;
}

- (id)delegate
{
  return text_delegate;
}

//
// Drawing
//
- (void)drawRect:(NSRect)rect
{
  [cell drawWithFrame:rect inView:self];
}

//
// Modifying Graphic Attributes 
//
- (NSColor *)backgroundColor
{
  return [cell backgroundColor];
}

- (BOOL)drawsBackground
{
  return [cell drawsBackground];
}

- (BOOL)isBezeled
{
  return [cell isBezeled];
}

- (BOOL)isBordered
{
  return [cell isBordered];
}

- (void)setBackgroundColor:(NSColor *)aColor
{
  [cell setBackgroundColor:aColor];
}

- (void)setBezeled:(BOOL)flag
{
  [cell setBezeled:flag];
}

- (void)setBordered:(BOOL)flag
{
  [cell setBordered:flag];
}

- (void)setDrawsBackground:(BOOL)flag
{
  [cell setDrawsBackground:flag];
}

- (void)setTextColor:(NSColor *)aColor
{
  [cell setTextColor:aColor];
}

- (NSColor *)textColor
{
  return [cell textColor];
}

//
// Target and Action 
//
- (SEL)errorAction
{
  return error_action;
}

- (void)setErrorAction:(SEL)aSelector
{
  error_action = aSelector;
}

//
// Handling Events 
//
- (void)mouseDown:(NSEvent *)theEvent
{
  // If not selectable then don't recognize the mouse down
  if (![self isSelectable]) return;

  [[self window] makeFirstResponder:self];
}

- (void)mouseUp:(NSEvent *)theEvent
{
  // If not selectable then don't recognize the mouse up
  if (![self isSelectable]) return;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
  // If not selectable then don't recognize the mouse moved
  if (![self isSelectable]) return;
}

- (void)keyDown:(NSEvent *)theEvent
{
  int result;
  unsigned int flags = [theEvent modifierFlags];
  unsigned int key_code = [theEvent keyCode];
  char out[80];

  // If SHIFT-TAB key then make the previous text the first responder
  if ((key_code == 0x09) && (flags & NSShiftKeyMask))
    {
      if ([previous_text respondsToSelector:@selector(selectText:)])
	// Either select the previous' text
	[previous_text selectText:self];
      else
	// Or select ourself
	[self selectText:self];

      // Have the target perform the action
      [self sendAction:[self action] to:[self target]];

      return;
    }

  // If TAB key then make the next text the first responder
  if (key_code == 0x09)
    {
      if ([next_text respondsToSelector:@selector(selectText:)])
	// Either select the next's text
	[next_text selectText:self];
      else
	// Or select ourself
	[self selectText:self];

      // Have the target perform the action
      [self sendAction:[self action] to:[self target]];

      return;
    }

  // If RETURN key then make the next text the first responder
  if (key_code == 0x0d)
    {
      if ([next_text respondsToSelector:@selector(selectText:)])
	// Either select the next's text
	[next_text selectText:self];
      else
	// Or select ourself
	[self selectText:self];

      // Have the target perform the action
      [self sendAction:[self action] to:[self target]];

      return;
    }

  // If not editable then don't recognize the key down
  if (![self isEditable]) return;
}

- (void)keyUp:(NSEvent *)theEvent
{
  unsigned int key_code = [theEvent keyCode];

  // Ignore TAB and RETURN key
  if ((key_code == 0x09) || (key_code == 0x0d))
    {
      return;
    }

  // If not editable then don't recognize the key up
  if (![self isEditable]) return;
}

- (BOOL)acceptsFirstResponder
{
  if ([self isSelectable])
    return YES;
  else
    return NO;
}

- (BOOL)becomeFirstResponder
{
  if ([self isSelectable])
    {
      [cell selectText:self];
      return YES;
    }
  else
    {
      return NO;
    }
}

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
  if ([text_delegate respondsTo:@selector(textDidBeginEditing:)])
    return [text_delegate textDidBeginEditing:aNotification];
}

- (void)textDidChange:(NSNotification *)aNotification
{
  if ([text_delegate respondsTo:@selector(textDidChange:)])
    return [text_delegate textDidChange:aNotification];
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
  if ([text_delegate respondsTo:@selector(textDidEndEditing:)])
    return [text_delegate textDidEndEditing:aNotification];
}

- (BOOL)textShouldBeginEditing:(NSText *)textObject
{
  return YES;
}

- (BOOL)textShouldEndEditing:(NSText *)textObject
{
  return YES;
}

//
// Manage the cursor
//
- (void)resetCursorRects
{
  [self addCursorRect: bounds cursor: text_cursor];
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeObjectReference: next_text withName: @"Next text"];
  [aCoder encodeObjectReference: previous_text withName: @"Previous text"];
  [aCoder encodeObjectReference: text_delegate withName: @"Text delegate"];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &error_action];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  [aDecoder decodeObjectAt: &next_text withName: NULL];
  [aDecoder decodeObjectAt: &previous_text withName: NULL];
  [aDecoder decodeObjectAt: &text_delegate withName: NULL];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &error_action];

  return self;
}

@end

