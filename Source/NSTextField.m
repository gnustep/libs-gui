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
id _nsTextfieldCellClass = nil;

//
// Class methods
//
+ (void) initialize
{
  if (self == [NSTextField class])
    {
      [self setVersion: 1];
      [self setCellClass: [NSTextFieldCell class]];
    }
}

//
// Initializing the NSTextField Factory
//
+ (Class) cellClass
{
  return _nsTextfieldCellClass;
}

+ (void) setCellClass: (Class)classId
{
  _nsTextfieldCellClass = classId;
}

//
// Instance methods
//
- (id) init
{
  return [self initWithFrame: NSZeroRect];
}

- (id) initWithFrame: (NSRect)frameRect
{
  NSTextFieldCell	*c;

  [super initWithFrame: frameRect];
  c = [_nsTextfieldCellClass new];
  [self setCell: c];
  [c release];
  [cell setState: 1];
  [cell setBezeled: YES];
  [cell setSelectable: YES];
  [cell setEnabled: YES];
  [cell setEditable: YES];
  [cell setDrawsBackground: YES];
  text_cursor = [[NSCursor IBeamCursor] retain];

  return self;
}

- (void) dealloc
{
  [text_cursor release];
  [super dealloc];
}

//
// Creating copies
//
- (void) setTextCursor: (NSCursor *)aCursor
{
  [aCursor retain];
  [text_cursor release];
  text_cursor = aCursor;
}

- (id) copyWithZone: (NSZone*)zone
{
  id c;

  c = [(id)super copyWithZone: zone];
  [c setTextCursor: [NSCursor IBeamCursor]];

  return c;
}

//
// Setting User Access to Text
//
- (BOOL) isEditable
{
  return [cell isEditable];
}

- (BOOL) isSelectable
{
  return [cell isSelectable];
}

- (void) setEditable: (BOOL)flag
{
  [cell setEditable: flag];
}

- (void) setSelectable: (BOOL)flag
{
  [cell setSelectable: flag];
}

//
// Editing Text
//
- (void) selectText: (id)sender
{
  if ([[self window] makeFirstResponder: self])
    [cell selectText: sender];
  [self setNeedsDisplay: YES];
}

//
// Setting Tab Key Behavior
//
- (id) nextText
{
  return next_text;
}

- (id) previousText
{
  return previous_text;
}

- (void) setNextText: (id)anObject
{
  id t;

  // Tell the object that we are the previous text Unless it already is
  next_text = anObject;
  if ([anObject respondsToSelector: @selector(setPreviousText:)])
    {
      t = [anObject previousText];
      if (t != self)
	[anObject setPreviousText: self];
    }
}

- (void) setPreviousText: (id)anObject
{
  id t;

  // Tell the object that we are the next text Unless it already knows
  previous_text = anObject;
  if ([anObject respondsToSelector: @selector(setNextText:)])
    {
      t = [anObject nextText];
      if (t != self)
	[anObject setNextText: self];
    }
}

//
// Assigning a Delegate
//
- (void) setDelegate: (id)anObject
{
  text_delegate = anObject;
}

- (id) delegate
{
  return text_delegate;
}

//
// Drawing
//
- (void) drawRect: (NSRect)rect
{
  [cell drawWithFrame: rect inView: self];
}

//
// Modifying Graphic Attributes
//
- (void) setBackgroundColor: (NSColor *)aColor
{
  [cell setBackgroundColor: aColor];
}

- (NSColor *) backgroundColor
{
  return [cell backgroundColor];
}

- (BOOL) drawsBackground
{
  return [cell drawsBackground];
}

- (BOOL) isBezeled
{
  return [cell isBezeled];
}

- (BOOL) isBordered
{
  return [cell isBordered];
}

- (void) setBezeled: (BOOL)flag
{
  [cell setBezeled: flag];
}

- (void) setBordered: (BOOL)flag
{
  [cell setBordered: flag];
}

- (void) setDrawsBackground: (BOOL)flag
{
  [cell setDrawsBackground: flag];
}

- (void) setTextColor: (NSColor *)aColor
{
  [cell setTextColor: aColor];
}

- (NSColor *) textColor
{
  return [cell textColor];
}

- (id) selectedCell
{
  return cell;
}

//
// Target and Action
//
- (SEL) errorAction
{
  return error_action;
}

- (void) setErrorAction: (SEL)aSelector
{
  error_action = aSelector;
}

//
// Handling Events
//
- (void) mouseDown: (NSEvent*)theEvent
{
  NSRect cellFrame = bounds;

  if (![self isSelectable])
    return;

fprintf(stderr, " TextField mouseDown --- ");

//	location = [self convertPoint: [theEvent locationInWindow] fromView: nil];
//	[self lockFocus];
//	cellFrame = [self convertRect: frame toView: nil];
//	cellFrame.origin = [super_view convertPoint: frame.origin
//					 toView: [window contentView]];

  if ([cell isBordered])
    {
      cellFrame.origin.x += 1;
      cellFrame.origin.y += 1;
      cellFrame.size.width -= 2;
      cellFrame.size.height -= 2;
    }
  else if ([cell isBezeled])
    {
      cellFrame.origin.x += 4;
      cellFrame.origin.y += 2;
      cellFrame.size.width -= 6;
      cellFrame.size.height -= 4;
    }

  fprintf (stderr,
	"XRTextField 0: rect origin (%1.2f, %1.2f), size (%1.2f, %1.2f)\n",
				frame.origin.x, frame.origin.y,
				frame.size.width, frame.size.height);
  fprintf (stderr,
	"XRTextField 1: rect origin (%1.2f, %1.2f), size (%1.2f, %1.2f)\n",
				cellFrame.origin.x, cellFrame.origin.y,
				cellFrame.size.width, cellFrame.size.height);

  [cell editWithFrame: cellFrame
	       inView: self
	       editor: [window fieldEditor: YES forObject: cell]
	     delegate: self
		event: theEvent];

//	[[self cell] _setCursorLocation: location];
//	[[self cell] _setCursorVisibility: YES];
//	[cell drawWithFrame: bounds inView: self];
//	[window flushWindow];
//	[self unlockFocus];
//	if ([[self window] makeFirstResponder: self])
//		[self setNeedsDisplay: YES];
}

- (void) mouseUp: (NSEvent *)theEvent
{
  if (![self isSelectable])
    return;
}

- (void) mouseMoved: (NSEvent *)theEvent
{
  if (![self isSelectable])
    return;
}

/*
 * Get characters until you encounter
 * a carriage return, return number of characters.
 * Deal with backspaces, etc.  Deal with Expose events
 * on all windows associated with this application.
 * Deal with keyboard remapping.
 */

- (void) keyDown: (NSEvent *)theEvent
{
  unsigned int flags = [theEvent modifierFlags];
  unsigned int key_code = [theEvent keyCode];
  id nextResponder;

  NSLog(@"NSTextField: -keyDown %s\n", [[theEvent characters] cString]);

  // If TAB, SHIFT-TAB or RETURN key then make another text the first
  // responder. This depends on key.
  if (key_code == 0x09 || key_code == 0x0d) {
    if (key_code == 0x09 && (flags & NSShiftKeyMask))
      nextResponder = previous_text;
    else
      nextResponder = next_text;

    if ([nextResponder respondsToSelector: @selector(selectText: )])
      // Either select the previous' text
      [nextResponder selectText: self];
    else
      // Or select ourself
      [self selectText: self];

    // Have the target perform the action
    [self sendAction: [self action] to: [self target]];
    return;
  }

  // If not editable then don't recognize the key down
  if (![self isEditable]) return;


#if 1
{
  NSRect cellFrame = bounds;

  if ([cell isBordered])
    {
      cellFrame.origin.x += 1;
      cellFrame.origin.y += 1;
      cellFrame.size.width -= 2;
      cellFrame.size.height -= 2;
    }
  else if ([cell isBezeled])
    {
      cellFrame.origin.x += 4;
      cellFrame.origin.y += 2;
      cellFrame.size.width -= 6;
      cellFrame.size.height -= 4;
    }

  [cell editWithFrame: cellFrame
	       inView: self
	       editor: [window fieldEditor: YES forObject: cell]
	     delegate: self
		event: theEvent];
}
#else
  // Hide the cursor during typing
  [NSCursor hide];

  [self lockFocus];
  [[self cell] _handleKeyEvent: theEvent];
  [cell drawWithFrame: bounds inView: self];
  [window flushWindow];
  [self unlockFocus];
//  [self setNeedsDisplay: YES];
#endif
}

- (void) keyUp: (NSEvent *)theEvent
{
  unsigned int key_code = [theEvent keyCode];

  // Ignore TAB and RETURN key
  if ((key_code == 0x09) || (key_code == 0x0d))
    {
      return;
    }

  // If not editable then don't recognize the key up
  if (![self isEditable])
    return;
}

- (BOOL) acceptsFirstResponder
{
  if ([self isSelectable] || [self isEditable])
    return YES;
  else
    return NO;
}

- (BOOL) becomeFirstResponder
{
  if ([self isSelectable])
    {
      [cell selectText: self];
      return YES;
    }
  else
    {
      return NO;
    }
}

- (void) textDidBeginEditing: (NSNotification *)aNotification
{
  if ([text_delegate respondsToSelector: @selector(textDidBeginEditing: )])
    return [text_delegate textDidBeginEditing: aNotification];
}

- (void) textDidChange: (NSNotification *)aNotification
{
  if ([text_delegate respondsToSelector: @selector(textDidChange: )])
    return [text_delegate textDidChange: aNotification];
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  if ([text_delegate respondsToSelector: @selector(textDidEndEditing: )])
    return [text_delegate textDidEndEditing: aNotification];
}

- (BOOL) textShouldBeginEditing: (NSText *)textObject
{
  return YES;
}

- (BOOL) textShouldEndEditing: (NSText *)aTextObject
{
  if ([cell isEntryAcceptable: [aTextObject text]])
    {
//		if ([delegate respondsTo: control: textShouldEndEditing: ])		// FIX ME
//			{
//			if (![delegate control: textShouldEndEditing: ])
//				{
//				NSBeep();
//				return NO;
//				}
//			else
//				return YES;
//			}
      [cell endEditing: aTextObject];
    }
  else
    {		// entry is not valid
      NSBeep();
      return NO;
    }

  return YES;
}

//
// Manage the cursor
//
- (void) resetCursorRects
{
  [self addCursorRect: bounds cursor: text_cursor];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeConditionalObject: next_text];
  [aCoder encodeConditionalObject: previous_text];
  [aCoder encodeConditionalObject: text_delegate];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &error_action];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  next_text = [aDecoder decodeObject];
  previous_text = [aDecoder decodeObject];
  text_delegate = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &error_action];

  return self;
}

@end

