/* 
   NSTextField.m

   Text field control class for text entry

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   
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

#include <AppKit/NSTextField.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSCursor.h>



@implementation NSTextField

//
// class variables
//
id gnustep_gui_nstextfield_cell_class = nil;

//
// Class methods
//
+ (void)initialize
{
	if (self == [NSTextField class])
		{
		[self setVersion:1];							// Set cell class to
		[self setCellClass:[NSTextFieldCell class]];	// NSTextFieldCell
		}
}

//
// Initializing the NSTextField Factory 
//
+ (Class)cellClass
{
	return gnustep_gui_nstextfield_cell_class;
}

+ (void)setCellClass:(Class)classId
{
	gnustep_gui_nstextfield_cell_class = classId;
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
	[self setCell:[[gnustep_gui_nstextfield_cell_class new] autorelease]];
	[cell setState:1];
	text_cursor = [[NSCursor IBeamCursor] retain];

	return self;
}

- (void)dealloc
{
	[text_cursor release];
	[super dealloc];
}

//
// Creating copies
//
- (void)setTextCursor:(NSCursor *)aCursor
{
	[aCursor retain];
	[text_cursor release];
	text_cursor = aCursor;
}

- copyWithZone:(NSZone *)zone
{
id c;

	c = [super copyWithZone: zone];
	[c setTextCursor: [NSCursor IBeamCursor]];

	return c;
}

//
// Setting User Access to Text 
//
- (BOOL)isEditable						{  return [cell isEditable]; }
- (BOOL)isSelectable					{ return [cell isSelectable]; }
- (void)setEditable:(BOOL)flag			{ [cell setEditable:flag]; }
- (void)setSelectable:(BOOL)flag		{ [cell setSelectable:flag]; }

//
// Editing Text 
//
- (void)selectText:(id)sender
{
	if ([[self window] makeFirstResponder:self])
		[cell selectText:sender];
	[self setNeedsDisplay:YES];
}

//
// Setting Tab Key Behavior 
//
- (id)nextText							{ return next_text; }
- (id)previousText						{ return previous_text; }

- (void)setNextText:(id)anObject
{
id t;
													// Tell the object that we
	next_text = anObject;							// are the previous text 
													// Unless it already is
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
													// Tell the object that we 
	previous_text = anObject;						// are the next text
													// Unless it already knows
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
- (void)setDelegate:(id)anObject		{ text_delegate = anObject; }
- (id)delegate							{ return text_delegate; }

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
- (void)setBackgroundColor:(NSColor *)aColor
{
	[cell setBackgroundColor:aColor];
}

- (NSColor *)backgroundColor			{ return [cell backgroundColor]; }
- (BOOL)drawsBackground					{ return [cell drawsBackground]; }
- (BOOL)isBezeled						{ return [cell isBezeled]; }
- (BOOL)isBordered						{ return [cell isBordered]; }
- (void)setBezeled:(BOOL)flag			{ [cell setBezeled:flag]; }
- (void)setBordered:(BOOL)flag			{ [cell setBordered:flag]; }
- (void)setDrawsBackground:(BOOL)flag	{ [cell setDrawsBackground:flag]; }
- (void)setTextColor:(NSColor *)aColor 	{ [cell setTextColor:aColor]; }
- (NSColor *)textColor					{ return [cell textColor]; }
- (id)selectedCell						{ return cell; }

//
// Target and Action 
//
- (SEL)errorAction						{ return error_action; }
- (void)setErrorAction:(SEL)aSelector	{ error_action = aSelector; }

- (void)displayRect:(NSRect)rect					// not per OS spec FIX ME
{
	[super displayRect:rect];
	[window flushWindow];
}

//
// Handling Events 
//
- (void)mouseDown:(NSEvent *)theEvent
{
NSPoint location;									
													// If not selectable then 
	if (![self isSelectable]) 						// don't recognize the 
		return;										// mouse down

fprintf(stderr, " TextField mouseDown --- ");

	location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	[self lockFocus];
	[[self cell] _setCursorLocation:location];
	[[self cell] _setCursorVisibility: YES];
	[cell drawWithFrame:bounds inView:self];
	[window flushWindow];
	[self unlockFocus];
	if ([[self window] makeFirstResponder:self])
		[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (![self isSelectable]) 						// If not selectable then 
		return;										// don't recognize the 
}													// mouse up

- (void)mouseMoved:(NSEvent *)theEvent
{
	if (![self isSelectable]) 						// If not selectable then 
		return;										// don't recognize the 
}													// mouse moved

/*
 * Get characters until you encounter
 * a carriage return, return number of characters.
 * Deal with backspaces, etc.  Deal with Expose events
 * on all windows associated with this application.
 * Deal with keyboard remapping.
 */

- (void)keyDown:(NSEvent *)theEvent
{
unsigned int flags = [theEvent modifierFlags];
unsigned int key_code = [theEvent keyCode];
id nextResponder;

  NSDebugLog(@"NSTextField: -keyDown %s\n", [[theEvent characters] cString]);

  // If TAB, SHIFT-TAB or RETURN key then make another text the first
  // responder. This depends on key.
  if (key_code == 0x09 || key_code == 0x0d) {
    if (key_code == 0x09 && (flags & NSShiftKeyMask))
      nextResponder = previous_text;
    else
      nextResponder = next_text;

    if ([nextResponder respondsToSelector:@selector(selectText:)])
      // Either select the previous' text
      [nextResponder selectText:self];
    else
      // Or select ourself
      [self selectText:self];

    // Have the target perform the action
    [self sendAction:[self action] to:[self target]];
    return;
  }

  // If not editable then don't recognize the key down
  if (![self isEditable]) return;

  // Hide the cursor during typing
  [NSCursor hide];

  [self lockFocus];
  [[self cell] _handleKeyEvent:theEvent];
  [cell drawWithFrame:bounds inView:self];
  [window flushWindow];
  [self unlockFocus];
//  [self setNeedsDisplay:YES];
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
  if ([text_delegate respondsToSelector:@selector(textDidBeginEditing:)])
    return [text_delegate textDidBeginEditing:aNotification];
}

- (void)textDidChange:(NSNotification *)aNotification
{
  if ([text_delegate respondsToSelector:@selector(textDidChange:)])
    return [text_delegate textDidChange:aNotification];
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
  if ([text_delegate respondsToSelector:@selector(textDidEndEditing:)])
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

#if 0
  [aCoder encodeObjectReference: next_text withName: @"Next text"];
  [aCoder encodeObjectReference: previous_text withName: @"Previous text"];
  [aCoder encodeObjectReference: text_delegate withName: @"Text delegate"];
#else
  [aCoder encodeConditionalObject:next_text];
  [aCoder encodeConditionalObject:previous_text];
  [aCoder encodeConditionalObject:text_delegate];
#endif
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &error_action];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

#if 0
  [aDecoder decodeObjectAt: &next_text withName: NULL];
  [aDecoder decodeObjectAt: &previous_text withName: NULL];
  [aDecoder decodeObjectAt: &text_delegate withName: NULL];
#else
  next_text = [aDecoder decodeObject];
  previous_text = [aDecoder decodeObject];
  text_delegate = [aDecoder decodeObject];
#endif
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &error_action];

  return self;
}

@end

