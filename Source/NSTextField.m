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
  return [self _initFieldWithFrame:frameRect cellClass:_nsTextfieldCellClass];
}

/*
===============
-_initFieldWithFrame:cellClass:
===============
*/
- (id)_initFieldWithFrame:(NSRect)frameRect cellClass:(Class)cellClass
{
  id c;

  [super initWithFrame: frameRect];
  c = [cellClass new];
  [self setCell: c];
  [c release];
  [cell setState: 1];
  [cell setBezeled: YES];
  [cell setSelectable: YES];
  [cell setEnabled: YES];
  [cell setEditable: YES];
  [self setDrawsBackground: YES];
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
  // TODO
  /*
  if (window)
    {
      if ([window makeFirstResponder: self])
	[cell selectText: sender];
      [self setNeedsDisplay: YES];
    }
  */
}

//
// Setting Tab Key Behavior
//
- (id) nextText
{
  return _nextKeyView;
}

- (id) previousText
{
  return _previousKeyView;
}

- (void) setNextText: (id)anObject
{
  [self setNextKeyView: anObject];
}

- (void) setPreviousText: (id)anObject
{
  [self setPreviousKeyView: anObject];
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

// This is called if a key is pressed when an editing session
// is not yet started.  (If needed, we start it from here).
- (void) keyDown: (NSEvent *)theEvent
{
  unsigned int key_code = [theEvent keyCode];
  
  NSDebugLLog(@"NSText", @"NSTextField: -keyDown %s\n", 
	      [[theEvent characters] cString]);
  
  // If not editable then we ignore the key down, pass it on
  if (![self isEditable]) 
    {
      [super keyDown: theEvent];
      return;
    }
  
  // If the key is TAB (with or without SHIFT) or ESC, pass it on
  if ((key_code == 0x09) || (key_code == 0x1b))
    {
      [super keyDown: theEvent];
      return;
    }
  
  // We handle ENTER here, to avoid setting up an editing session 
  // only for it.
  if (key_code == 0x0d)
    {
      [self sendAction: [cell action] to: [cell target]];
      [window selectKeyViewFollowingView: self];
      return;
    }
  
  // Otherwise, start an editing session (FIXME the following)
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

- (BOOL) acceptsFirstResponder
{
  if ([self isSelectable] || [self isEditable])
    return YES;
  else
    return NO;
}

- (BOOL) becomeFirstResponder
{
  if ([self isSelectable] || [self isEditable])
    {
      [self selectText: self];
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

//  [self display];
//  [window flushWindow];

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

  [aCoder encodeConditionalObject: text_delegate];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &error_action];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  text_delegate = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &error_action];

  return self;
}

@end

